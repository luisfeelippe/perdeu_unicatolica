import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente HTTP para centralizar as chamadas da API.
class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api';

  Future<Map<String, String>> _getHeaders({
    Map<String, String>? extraHeaders,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token') ??
        prefs.getString('jwt') ??
        prefs.getString('jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _getHeaders(
      extraHeaders: headers,
    );

    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _getHeaders(
      extraHeaders: headers,
    );

    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _getHeaders(
      extraHeaders: headers,
    );

    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _getHeaders(
      extraHeaders: headers,
    );

    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await _getHeaders(
      extraHeaders: headers,
    );

    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );
  }
}