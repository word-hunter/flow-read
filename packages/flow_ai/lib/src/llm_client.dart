import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'ai_provider_config.dart';

enum AIClientErrorType {
  unauthorized,
  rateLimited,
  networkError,
  timeout,
  serverError,
  unknown,
}

class AIClientException implements Exception {
  final String message;
  final AIClientErrorType type;

  AIClientException(this.message, this.type);

  @override
  String toString() => message;
}

class LLMClient {
  final AIProviderConfig Function() _configProvider;
  final http.Client _httpClient;

  LLMClient(this._configProvider, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<bool> testConnection({
    String? apiKey,
    AIProviderConfig? config,
  }) async {
    try {
      final resolved = (config ?? _configProvider()).copyWith(
        apiKey: apiKey,
      );
      final uri = _chatCompletionsUri(resolved);
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${resolved.apiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': resolved.model,
              'messages': [
                {'role': 'user', 'content': 'ping'},
              ],
              'max_tokens': 5,
              'temperature': 0.0,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
  }) async {
    final config = _configProvider();
    _ensureApiKey(config);

    final body = _buildBody(
      config,
      systemPrompt,
      userPrompt,
      jsonMode: jsonMode,
    );
    return _retryRequest(() => _doChat(body, config));
  }

  Stream<String> streamChat({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
  }) async* {
    final config = _configProvider();
    _ensureApiKey(config);

    final body = _buildBody(
      config,
      systemPrompt,
      userPrompt,
      jsonMode: jsonMode,
    );

    final uri = _chatCompletionsUri(config);
    final request = http.Request('POST', uri);
    request.headers['Authorization'] = 'Bearer ${config.apiKey}';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final response = await _httpClient.send(request);
    await _validateNonStream(response);

    await for (final chunk in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      yield* _processStreamChunk(chunk);
    }
  }

  Future<bool> validateApiKey(AIProviderConfig config) async {
    final resolved = _configProvider().copyWith(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model: config.model,
    );
    return testConnection(config: resolved);
  }

  Uri _chatCompletionsUri(AIProviderConfig config) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    return Uri.parse('$base/chat/completions');
  }

  Map<String, dynamic> _buildBody(
    AIProviderConfig config,
    String systemPrompt,
    String userPrompt, {
    bool jsonMode = false,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    final body = <String, dynamic>{
      'model': config.model,
      'messages': messages,
      'temperature': 0.3,
      'stream': false,
    };

    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    return body;
  }

  void _ensureApiKey(AIProviderConfig config) {
    if (config.apiKey.trim().isEmpty) {
      throw AIClientException('API key not configured', AIClientErrorType.unauthorized);
    }
  }

  Future<String> _doChat(Map<String, dynamic> body, AIProviderConfig config) async {
    final uri = _chatCompletionsUri(config);
    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));
    return _handleResponse(response);
  }

  Future<String> _retryRequest(Future<String> Function() request) async {
    var attempts = 0;
    const maxRetries = 3;

    while (true) {
      try {
        return await request();
      } on AIClientException catch (e) {
        if (e.type == AIClientErrorType.rateLimited && attempts < maxRetries) {
          attempts++;
          final delay = Duration(seconds: pow(2, attempts).toInt() * 2);
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIClientException(
        'API authentication failed (${response.statusCode}). Please check your API key.',
        AIClientErrorType.unauthorized,
      );
    }
    if (response.statusCode == 429) {
      throw AIClientException(
        'Rate limited. Please wait before retrying.',
        AIClientErrorType.rateLimited,
      );
    }
    if (response.statusCode >= 500) {
      throw AIClientException(
        'Server error (${response.statusCode}). The AI service may be temporarily unavailable.',
        AIClientErrorType.serverError,
      );
    }
    if (response.statusCode != 200) {
      throw AIClientException(
        'Unexpected response (${response.statusCode}): ${response.body}',
        AIClientErrorType.unknown,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw AIClientException(
          'No response from AI. The model returned an empty result.',
          AIClientErrorType.unknown,
        );
      }
      final message = choices.first['message'] as Map<String, dynamic>;
      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AIClientException(
          'Empty response from AI. The model did not generate any content.',
          AIClientErrorType.unknown,
        );
      }
      return content;
    } catch (e) {
      if (e is AIClientException) rethrow;
      throw AIClientException(
        'Failed to parse AI response: $e',
        AIClientErrorType.unknown,
      );
    }
  }

  Future<void> _validateNonStream(http.StreamedResponse response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIClientException(
        'API authentication failed (${response.statusCode})',
        AIClientErrorType.unauthorized,
      );
    }
    if (response.statusCode == 429) {
      throw AIClientException(
        'Rate limited',
        AIClientErrorType.rateLimited,
      );
    }
    if (response.statusCode >= 500) {
      throw AIClientException(
        'Server error (${response.statusCode})',
        AIClientErrorType.serverError,
      );
    }
    if (response.statusCode != 200) {
      throw AIClientException(
        'Unexpected response (${response.statusCode})',
        AIClientErrorType.unknown,
      );
    }
  }

  Stream<String> _processStreamChunk(String chunk) async* {
    final trimmed = chunk.trim();
    if (!trimmed.startsWith('data: ')) return;
    final data = trimmed.substring(6);
    if (data == '[DONE]') return;

    try {
      final parsed = jsonDecode(data) as Map<String, dynamic>;
      final choices = parsed['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return;
      final delta = choices.first['delta'] as Map<String, dynamic>?;
      final content = delta?['content'] as String?;
      if (content != null) yield content;
    } catch (_) {}
  }

  void dispose() {
    _httpClient.close();
  }
}
