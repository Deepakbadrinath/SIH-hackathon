import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../error/failures.dart';
import '../security/secure_storage_service.dart';

abstract class INetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfo implements INetworkInfo {
  bool? _mockConnected;

  void setMockConnectionStatus(bool? isConnected) {
    _mockConnected = isConnected;
  }

  bool? get mockConnectionStatus => _mockConnected;

  @override
  Future<bool> get isConnected async {
    if (_mockConnected != null) {
      return _mockConnected!;
    }
    // Basic ping / connectivity check
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}

class HttpClientWrapper {
  final http.Client _client;
  final TokenVault _tokenVault;

  HttpClientWrapper({
    http.Client? client,
    required TokenVault tokenVault,
  })  : _client = client ?? http.Client(),
        _tokenVault = tokenVault;

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Version': AppConfig.current.appVersion,
    };
    final token = await _tokenVault.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.current.apiBaseUrl}$path');
    final headers = await _getHeaders();

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: json.encode(body),
          )
          .timeout(AppConfig.current.apiTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Sanitize error response to prevent raw body leakage into logs or UI
        String safeMessage = 'Request failed with status ${response.statusCode}';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            final msg = decoded['message'];
            if (msg is String && msg.isNotEmpty && msg.length < 256) {
              safeMessage = msg;
            } else if (msg is List && msg.isNotEmpty) {
              safeMessage = msg.take(3).join(', ');
            }
          }
        } catch (_) {
          // Response body was not JSON or invalid - keep generic sanitized message
        }

        throw NetworkFailure(
          safeMessage,
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('Network communication error occurred. Please verify your connection.');
    }
  }
}
