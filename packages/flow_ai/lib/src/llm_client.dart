import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'ai_debug_trace_recorder.dart';
import 'ai_provider_config.dart';
import 'models/token_usage_info.dart';

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

class ChatCompletionResult {
  const ChatCompletionResult({
    required this.content,
    required this.providerId,
    required this.model,
    required this.durationMs,
    this.usage,
  });

  final String content;
  final TokenUsageInfo? usage;
  final String providerId;
  final String model;
  final int durationMs;
}

class ChatStreamChunk {
  const ChatStreamChunk({
    this.content = '',
    this.usage,
    this.isFinal = false,
  });

  final String content;
  final TokenUsageInfo? usage;
  final bool isFinal;
}

class LLMClient {
  final AIProviderConfig Function() _configProvider;
  final http.Client _httpClient;
  final AIDebugTraceRecorder _debugRecorder;

  LLMClient(
    this._configProvider, {
    http.Client? httpClient,
    AIDebugTraceRecorder? debugRecorder,
  }) : _httpClient = httpClient ?? http.Client(),
       _debugRecorder = debugRecorder ?? AIDebugTraceRecorder.instance;

  String get modelConfigFingerprint {
    final config = _configProvider();
    return [
      config.definition.id,
      config.normalizedBaseUrl,
      config.model.trim(),
    ].join('|');
  }

  Future<bool> testConnection({
    String? apiKey,
    AIProviderConfig? config,
  }) async {
    final stopwatch = Stopwatch()..start();
    AIProviderConfig? resolved;
    http.Response? response;
    try {
      resolved = (config ?? _configProvider()).copyWith(
        apiKey: apiKey,
      );
      final uri = _chatCompletionsUri(resolved);
      final body = {
        'model': resolved.model,
        'messages': [
          {'role': 'user', 'content': 'ping'},
        ],
        'max_tokens': 5,
        'temperature': 0.0,
      };
      final headers = {
        'Authorization': 'Bearer ${resolved.apiKey}',
        'Content-Type': 'application/json',
      };
      response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      _recordHttpTrace(
        operation: 'testConnection',
        config: resolved,
        uri: uri,
        headers: headers,
        body: body,
        response: response,
        stopwatch: stopwatch,
      );
      return response.statusCode == 200;
    } catch (error) {
      if (resolved != null) {
        _recordHttpTrace(
          operation: 'testConnection',
          config: resolved,
          uri: _chatCompletionsUri(resolved),
          headers: {
            'Authorization': 'Bearer ${resolved.apiKey}',
            'Content-Type': 'application/json',
          },
          body: {
            'model': resolved.model,
            'messages': [
              {'role': 'user', 'content': 'ping'},
            ],
            'max_tokens': 5,
            'temperature': 0.0,
          },
          response: response,
          stopwatch: stopwatch,
          error: error,
        );
      }
      return false;
    }
  }

  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    Map<String, Object?> debugMetadata = const {},
  }) async {
    final result = await chatWithResult(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: jsonMode,
      debugMetadata: debugMetadata,
    );
    return result.content;
  }

  Future<ChatCompletionResult> chatWithResult({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    Map<String, Object?> debugMetadata = const {},
  }) async {
    final config = _configProvider();
    _ensureApiKey(config);

    final body = _buildBody(
      config,
      systemPrompt,
      userPrompt,
      jsonMode: jsonMode,
    );
    return _retryRequest(
      (attempt) => _doChat(
        body,
        config,
        attempt: attempt,
        debugMetadata: debugMetadata,
      ),
    );
  }

  Stream<String> streamChat({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    Map<String, Object?> debugMetadata = const {},
  }) async* {
    await for (final chunk in streamChatWithChunks(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: jsonMode,
      debugMetadata: debugMetadata,
    )) {
      if (chunk.content.isNotEmpty) yield chunk.content;
    }
  }

  Stream<ChatStreamChunk> streamChatWithChunks({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    Map<String, Object?> debugMetadata = const {},
  }) async* {
    final config = _configProvider();
    _ensureApiKey(config);

    final body = _buildBody(
      config,
      systemPrompt,
      userPrompt,
      jsonMode: jsonMode,
      stream: true,
    );

    final uri = _chatCompletionsUri(config);
    final request = http.Request('POST', uri);
    request.headers['Authorization'] = 'Bearer ${config.apiKey}';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final stopwatch = Stopwatch()..start();
    http.StreamedResponse? response;
    final buffer = StringBuffer();
    try {
      response = await _httpClient.send(request);
      await _validateNonStream(response);

      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        await for (final parsedChunk in _processStreamChunk(chunk)) {
          buffer.write(parsedChunk.content);
          yield parsedChunk;
        }
      }
      _recordHttpTrace(
        operation: 'streamChat',
        config: config,
        uri: uri,
        headers: request.headers,
        body: body,
        streamedResponse: response,
        responseBody: buffer.toString(),
        stopwatch: stopwatch,
        stream: true,
        debugMetadata: debugMetadata,
      );
    } catch (error) {
      _recordHttpTrace(
        operation: 'streamChat',
        config: config,
        uri: uri,
        headers: request.headers,
        body: body,
        streamedResponse: response,
        responseBody: buffer.toString(),
        stopwatch: stopwatch,
        stream: true,
        debugMetadata: debugMetadata,
        error: error,
      );
      rethrow;
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
    bool stream = false,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    final body = <String, dynamic>{
      'model': config.model,
      'messages': messages,
      'temperature': 0.3,
      'stream': stream,
    };

    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    return body;
  }

  void _ensureApiKey(AIProviderConfig config) {
    if (config.apiKey.trim().isEmpty) {
      throw AIClientException(
        'API key not configured',
        AIClientErrorType.unauthorized,
      );
    }
  }

  Future<ChatCompletionResult> _doChat(
    Map<String, dynamic> body,
    AIProviderConfig config, {
    required int attempt,
    Map<String, Object?> debugMetadata = const {},
  }) async {
    final uri = _chatCompletionsUri(config);
    final headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
    };
    final stopwatch = Stopwatch()..start();
    http.Response? response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));
      final durationMs = stopwatch.elapsedMilliseconds;
      final result = _handleResponse(response, config, durationMs);
      _recordHttpTrace(
        operation: 'chat',
        config: config,
        uri: uri,
        headers: headers,
        body: body,
        response: response,
        stopwatch: stopwatch,
        debugMetadata: {
          ...debugMetadata,
          'attempt': attempt,
        },
      );
      return result;
    } catch (error) {
      _recordHttpTrace(
        operation: 'chat',
        config: config,
        uri: uri,
        headers: headers,
        body: body,
        response: response,
        stopwatch: stopwatch,
        debugMetadata: {
          ...debugMetadata,
          'attempt': attempt,
        },
        error: error,
      );
      rethrow;
    }
  }

  Future<T> _retryRequest<T>(
    Future<T> Function(int attempt) request,
  ) async {
    var attempts = 0;
    const maxRetries = 3;

    while (true) {
      try {
        return await request(attempts + 1);
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

  void _recordHttpTrace({
    required String operation,
    required AIProviderConfig config,
    required Uri uri,
    required Map<String, String> headers,
    required Object? body,
    http.Response? response,
    http.StreamedResponse? streamedResponse,
    Object? responseBody,
    required Stopwatch stopwatch,
    bool stream = false,
    Map<String, Object?> debugMetadata = const {},
    Object? error,
  }) {
    if (!_debugRecorder.enabled) return;
    stopwatch.stop();
    _debugRecorder.recordHttpInteraction(
      operation: operation,
      method: 'POST',
      url: uri,
      requestHeaders: headers,
      requestBody: body,
      responseHeaders:
          response?.headers ?? streamedResponse?.headers ?? const {},
      responseBody: responseBody ?? response?.body,
      statusCode: response?.statusCode ?? streamedResponse?.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
      stream: stream,
      metadata: {
        'providerId': config.definition.id,
        'providerLabel': config.definition.label,
        'model': config.model,
        'baseUrl': config.normalizedBaseUrl,
        ...debugMetadata,
      },
      error: error,
    );
  }

  ChatCompletionResult _handleResponse(
    http.Response response,
    AIProviderConfig config,
    int durationMs,
  ) {
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
      return ChatCompletionResult(
        content: content,
        usage: TokenUsageInfo.tryFromJson(data),
        providerId: config.definition.id,
        model: config.model,
        durationMs: durationMs,
      );
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

  Stream<ChatStreamChunk> _processStreamChunk(String chunk) async* {
    final trimmed = chunk.trim();
    if (!trimmed.startsWith('data: ')) return;
    final data = trimmed.substring(6);
    if (data == '[DONE]') {
      yield const ChatStreamChunk(isFinal: true);
      return;
    }

    try {
      final parsed = jsonDecode(data) as Map<String, dynamic>;
      final usage = TokenUsageInfo.tryFromJson(parsed);
      final choices = parsed['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        if (usage != null) {
          yield ChatStreamChunk(usage: usage, isFinal: true);
        }
        return;
      }
      final delta = choices.first['delta'] as Map<String, dynamic>?;
      final content = delta?['content'] as String?;
      if (content != null || usage != null) {
        yield ChatStreamChunk(
          content: content ?? '',
          usage: usage,
          isFinal: usage != null,
        );
      }
    } catch (_) {}
  }

  void dispose() {
    _httpClient.close();
  }
}
