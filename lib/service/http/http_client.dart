import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/api_result.dart';

import '../log/logger.dart';

class HttpClient {
  final String baseUrl;
  final Map<String, String>? authorizationHeaders;
  final Logger? logger;

  const HttpClient({
    required this.baseUrl,
    this.logger,
    this.authorizationHeaders,
  });

  Future<ApiResult<T>> get<T>({
    required String path,
    required T Function(http.Response) decoder,
    Map<String, Object> parameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final requestUrl = _buildRequestUrl(path, parameters: parameters);
    logger?.info('HTTP GET $requestUrl');

    try {
      final requestHeaders = _buildHeaders(requestHeaders: headers);

      final httpResponse = await http.get(
        Uri.parse(requestUrl),
        headers: requestHeaders,
      );

      if (httpResponse.statusCode != 200) {
        throw Exception('${httpResponse.statusCode} ${httpResponse.body}');
      }

      final data = decoder.call(httpResponse);

      return ApiResult.success(data);
    } on Exception catch (error) {
      logger?.error('HTTP GET FAILED', error);
      return ApiResult.failed(error);
    }
  }

  Future<ApiResult<T>> post<T>({
    required String path,
    required T Function(http.Response) decoder,
    Map<String, Object> parameters = const {},
    Map<String, String> headers = const {},
    required dynamic body,
  }) async {
    final requestUrl = _buildRequestUrl(path, parameters: parameters);
    logger?.info('HTTP POST $requestUrl');

    try {
      final requestHeaders = _buildHeaders(requestHeaders: headers);

      final httpResponse = await http.post(
        Uri.parse(requestUrl),
        headers: requestHeaders,
        body: jsonEncode(body),
      );

      if (httpResponse.statusCode != 200) {
        throw Exception('${httpResponse.statusCode} ${httpResponse.body}');
      }

      final data = decoder.call(httpResponse);

      return ApiResult.success(data);
    } on Exception catch (error) {
      logger?.error('HTTP POST FAILED', error);
      return ApiResult.failed(error);
    }
  }

  String _buildRequestUrl(
    String path, {
    Map<String, Object> parameters = const {},
  }) {
    var buff = StringBuffer();
    if (baseUrl.endsWith('/')) {
      buff.write(baseUrl.substring(0, baseUrl.length - 2));
    } else {
      buff.write(baseUrl);
    }

    buff.write('/');

    if (path.startsWith('/')) {
      buff.write(path.substring(1, path.length));
    } else {
      buff.write(path);
    }

    if (parameters.isNotEmpty) {
      buff.write('?');
      int parametersLen = parameters.length;
      int index = 0;
      for (final parameter in parameters.entries) {
        buff.write('${parameter.key}=${parameter.value}');
        if (index < parametersLen - 1) {
          buff.write('&');
        }
        index++;
      }
    }

    return buff.toString();
  }

  Map<String, String> _buildHeaders({
    Map<String, String> requestHeaders = const {},
  }) {
    if (authorizationHeaders == null) {
      return requestHeaders;
    }

    var map = Map<String, String>.from(requestHeaders);
    for (final kv in authorizationHeaders!.entries) {
      map[kv.key] = kv.value;
    }

    return map;
  }
}
