import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:developer' as developer;

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final Map<String, dynamic>? metadata;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success(T data, {int statusCode = 200, Map<String, dynamic>? metadata}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  factory ApiResponse.error(String error, {int statusCode = 500, Map<String, dynamic>? metadata}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      metadata: metadata,
    );
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late String _baseUrl;
  String? _authToken;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // WebSocket connections
  final Map<String, WebSocketChannel> _wsConnections = {};
  final Map<String, StreamController> _wsControllers = {};

  void initialize({
    required String baseUrl,
    String? authToken,
    Map<String, String>? defaultHeaders,
  }) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    _authToken = authToken;
    
    if (defaultHeaders != null) {
      _defaultHeaders.addAll(defaultHeaders);
    }
    
    developer.log('API Client initialized with base URL: $_baseUrl', name: 'ApiClient');
  }

  void setAuthToken(String token) {
    _authToken = token;
    _defaultHeaders['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _defaultHeaders.remove('Authorization');
  }

  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      developer.log('GET $uri', name: 'ApiClient');
      
      final response = await http.get(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
      ).timeout(timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      developer.log('GET request failed: $e', name: 'ApiClient');
      return ApiResponse.error('Request failed: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log('POST $uri', name: 'ApiClient');
      
      final response = await http.post(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      developer.log('POST request failed: $e', name: 'ApiClient');
      return ApiResponse.error('Request failed: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log('PUT $uri', name: 'ApiClient');
      
      final response = await http.put(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      developer.log('PUT request failed: $e', name: 'ApiClient');
      return ApiResponse.error('Request failed: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log('DELETE $uri', name: 'ApiClient');
      
      final response = await http.delete(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
      ).timeout(timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      developer.log('DELETE request failed: $e', name: 'ApiClient');
      return ApiResponse.error('Request failed: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log('PATCH $uri', name: 'ApiClient');
      
      final response = await http.patch(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      return _handleResponse<T>(response);
    } catch (e) {
      developer.log('PATCH request failed: $e', name: 'ApiClient');
      return ApiResponse.error('Request failed: $e');
    }
  }

  Future<ApiResponse<String>> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      final uri = _buildUri(endpoint);
      developer.log('UPLOAD $uri', name: 'ApiClient');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders(additionalHeaders: headers));
      
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<String>(response);
    } catch (e) {
      developer.log('File upload failed: $e', name: 'ApiClient');
      return ApiResponse.error('Upload failed: $e');
    }
  }

  Stream<T> connectWebSocket<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    final wsUrl = _baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl$endpoint');
    
    developer.log('Connecting WebSocket: $uri', name: 'ApiClient');
    
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: _getHeaders(additionalHeaders: headers),
    );
    
    final controller = StreamController<T>.broadcast();
    _wsConnections[endpoint] = channel;
    _wsControllers[endpoint] = controller;
    
    channel.stream.listen(
      (data) {
        try {
          final parsed = parser != null ? parser(data) : data as T;
          controller.add(parsed);
        } catch (e) {
          developer.log('WebSocket parsing error: $e', name: 'ApiClient');
          controller.addError(e);
        }
      },
      onError: (error) {
        developer.log('WebSocket error: $error', name: 'ApiClient');
        controller.addError(error);
      },
      onDone: () {
        developer.log('WebSocket connection closed: $endpoint', name: 'ApiClient');
        controller.close();
        _wsConnections.remove(endpoint);
        _wsControllers.remove(endpoint);
      },
    );
    
    return controller.stream;
  }

  void sendWebSocketMessage(String endpoint, dynamic message) {
    final connection = _wsConnections[endpoint];
    if (connection != null) {
      connection.sink.add(jsonEncode(message));
    } else {
      developer.log('WebSocket connection not found: $endpoint', name: 'ApiClient');
    }
  }

  void closeWebSocket(String endpoint) {
    final connection = _wsConnections[endpoint];
    final controller = _wsControllers[endpoint];
    
    if (connection != null) {
      connection.sink.close();
      _wsConnections.remove(endpoint);
    }
    
    if (controller != null) {
      controller.close();
      _wsControllers.remove(endpoint);
    }
  }

  void closeAllWebSockets() {
    for (final endpoint in _wsConnections.keys.toList()) {
      closeWebSocket(endpoint);
    }
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseUrl$path');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    
    return uri;
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    developer.log('Response ${response.statusCode}: ${response.body}', name: 'ApiClient');
    
    try {
      final dynamic responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          responseData as T,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers},
        );
      } else {
        final errorMessage = responseData is Map && responseData.containsKey('error')
            ? responseData['error']
            : 'Request failed with status ${response.statusCode}';
        
        return ApiResponse.error(
          errorMessage,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers, 'body': responseData},
        );
      }
    } catch (e) {
      // Handle non-JSON responses
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          response.body as T,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers},
        );
      } else {
        return ApiResponse.error(
          'Request failed with status ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
          metadata: {'headers': response.headers},
        );
      }
    }
  }

  // Batch requests
  Future<List<ApiResponse<T>>> batchRequests<T>(
    List<Future<ApiResponse<T>>> requests, {
    int? concurrencyLimit,
  }) async {
    if (concurrencyLimit != null && concurrencyLimit > 0) {
      final results = <ApiResponse<T>>[];
      
      for (int i = 0; i < requests.length; i += concurrencyLimit) {
        final batch = requests.skip(i).take(concurrencyLimit);
        final batchResults = await Future.wait(batch);
        results.addAll(batchResults);
      }
      
      return results;
    } else {
      return await Future.wait(requests);
    }
  }

  // Retry mechanism
  Future<ApiResponse<T>> retryRequest<T>(
    Future<ApiResponse<T>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(ApiResponse<T>)? shouldRetry,
  }) async {
    ApiResponse<T>? lastResponse;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        lastResponse = await request();
        
        if (lastResponse.success || (shouldRetry != null && !shouldRetry(lastResponse))) {
          return lastResponse;
        }
        
        if (attempt < maxRetries) {
          await Future.delayed(delay * (attempt + 1));
        }
      } catch (e) {
        if (attempt == maxRetries) {
          return ApiResponse.error('Request failed after $maxRetries retries: $e');
        }
        await Future.delayed(delay * (attempt + 1));
      }
    }
    
    return lastResponse ?? ApiResponse.error('Request failed after $maxRetries retries');
  }

  void dispose() {
    closeAllWebSockets();
  }
}
