import 'dart:convert';
import 'dart:typed_data';

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

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final res = await http.post(
      _uri(path, query),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required Uint8List fileBytes,
    required String filename,
    required Map<String, String> fields,
    Map<String, dynamic>? query,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path, query));
    req.fields.addAll(fields);
    req.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 400) {
      throw Exception(
        'API POST $path failed (${res.statusCode}): ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }
}

