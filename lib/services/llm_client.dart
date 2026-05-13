import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'settings_service.dart';

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
  static const _baseUrl = 'https://api.deepseek.com/v1';
  static const _model = 'deepseek-chat';

  final SettingsService _settings;

  LLMClient(this._settings);

  String? get _apiKey => _settings.apiKey;

  Future<bool> testConnection(String apiKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': 'hello'},
              ],
              'max_tokens': 5,
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
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw AIClientException(
        'API key 未配置，请在设置中配置 DeepSeek API Key',
        AIClientErrorType.unauthorized,
      );
    }

    final body = _buildBody(systemPrompt, userPrompt, jsonMode: jsonMode);
    return _retryRequest(() => _doChat(body));
  }

  Stream<String> streamChat({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
  }) async* {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw AIClientException(
        'API key 未配置，请在设置中配置 DeepSeek API Key',
        AIClientErrorType.unauthorized,
      );
    }

    final body = _buildBody(
      systemPrompt,
      userPrompt,
      jsonMode: jsonMode,
      stream: true,
    );
    final uri = Uri.parse('$_baseUrl/chat/completions');
    final bytes = utf8.encode(jsonEncode(body));
    final request = http.StreamedRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $key';
    request.headers['Content-Type'] = 'application/json';
    request.contentLength = bytes.length;
    request.sink.add(bytes);
    request.sink.close();

    http.StreamedResponse response;
    try {
      response = await request.send().timeout(const Duration(seconds: 180));
    } on TimeoutException {
      throw AIClientException('请求超时', AIClientErrorType.timeout);
    } on http.ClientException {
      throw AIClientException('网络连接失败', AIClientErrorType.networkError);
    }

    if (response.statusCode == 401) {
      throw AIClientException(
        'API key 无效，请检查设置',
        AIClientErrorType.unauthorized,
      );
    }
    if (response.statusCode == 429) {
      throw AIClientException('请求频率过高，请稍后重试', AIClientErrorType.rateLimited);
    }
    if (response.statusCode != 200) {
      throw AIClientException(
        '服务器错误 (${response.statusCode})',
        AIClientErrorType.serverError,
      );
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final content =
                json['choices']?[0]?['delta']?['content'] as String?;
            if (content != null) yield content;
          } catch (_) {}
        }
      }
    }
  }

  Map<String, dynamic> _buildBody(
    String systemPrompt,
    String userPrompt, {
    bool jsonMode = false,
    bool stream = false,
  }) {
    final body = <String, dynamic>{
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.1,
      'stream': stream,
    };

    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    return body;
  }

  Future<String> _doChat(Map<String, dynamic> body) async {
    final key = _apiKey!;
    final uri = Uri.parse('$_baseUrl/chat/completions');

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 180));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        throw AIClientException('响应格式异常', AIClientErrorType.serverError);
      }
      return content;
    } else if (response.statusCode == 401) {
      throw AIClientException(
        'API key 无效，请检查设置',
        AIClientErrorType.unauthorized,
      );
    } else if (response.statusCode == 429) {
      throw AIClientException('请求频率过高，请稍后重试', AIClientErrorType.rateLimited);
    } else {
      final body = response.body;
      String msg = '服务器错误 (${response.statusCode})';
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        final errMsg = err['error']?['message'] as String?;
        if (errMsg != null) msg = errMsg;
      } catch (_) {}
      throw AIClientException(msg, AIClientErrorType.serverError);
    }
  }

  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } on AIClientException catch (e) {
        if (e.type == AIClientErrorType.unauthorized) rethrow;
        if (e.type == AIClientErrorType.rateLimited) rethrow;
        if (i == maxRetries - 1) rethrow;
      } on TimeoutException {
        if (i == maxRetries - 1) {
          throw AIClientException('请求超时', AIClientErrorType.timeout);
        }
      } on http.ClientException {
        if (i == maxRetries - 1) {
          throw AIClientException('网络连接失败', AIClientErrorType.networkError);
        }
      }
      await Future.delayed(Duration(seconds: pow(2, i).toInt()));
    }
    throw AIClientException('未知错误', AIClientErrorType.unknown);
  }
}
