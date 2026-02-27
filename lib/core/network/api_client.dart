import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient() {
    final fromEnv = dotenv.env['RESQNET_API_BASE_URL'];
    _baseUrl = (fromEnv != null && fromEnv.isNotEmpty)
        ? fromEnv
        : 'https://7025-14-195-240-42.ngrok-free.app';
  }

  late final String _baseUrl;

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse(_baseUrl).replace(
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<List<dynamic>> getList(String path,
      {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query));
    if (res.statusCode >= 400) {
      throw Exception(
        'API GET $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final body = jsonDecode(res.body);
    if (body is List) return body;
    throw Exception('Expected list response for $path');
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query));
    if (res.statusCode >= 400) {
      throw Exception(
        'API GET $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body;
  }
}

