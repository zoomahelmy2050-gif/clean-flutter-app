import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class ErrorHandler {
  static void handleError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? context,
    bool showToUser = true,
    BuildContext? buildContext,
  }) {
    // Log the error
    developer.log(
      'Error occurred${context != null ? ' in $context' : ''}: $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // Show user-friendly message if context is available
    if (showToUser && buildContext != null && buildContext.mounted) {
      _showErrorToUser(buildContext, error, context);
    }
  }

  static void _showErrorToUser(BuildContext context, dynamic error, String? errorContext) {
    final message = _getUserFriendlyMessage(error, errorContext);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () => _showErrorDialog(context, error, errorContext),
        ),
      ),
    );
  }

  static String _getUserFriendlyMessage(dynamic error, String? context) {
    if (error is SecurityServiceException) {
      return error.userMessage;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    }
    
    if (errorString.contains('authentication') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please log in again.';
    }
    
    if (context != null) {
      return 'An error occurred in $context. Please try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  static void _showErrorDialog(BuildContext context, dynamic error, String? errorContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorContext != null) ...[
                Text(
                  'Context:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(errorContext),
                const SizedBox(height: 16),
              ],
              Text(
                'Error:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(error.toString()),
              const SizedBox(height: 16),
              Text(
                'What you can do:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(_getRecoveryInstructions(error)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: error.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error details copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _getRecoveryInstructions(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return '• Check your internet connection\n• Try again in a few moments\n• Contact support if the issue persists';
    }
    
    if (errorString.contains('timeout')) {
      return '• Try the operation again\n• Check your network speed\n• Contact support if timeouts continue';
    }
    
    if (errorString.contains('permission')) {
      return '• Check your user permissions\n• Contact your administrator\n• Try logging out and back in';
    }
    
    if (errorString.contains('authentication')) {
      return '• Log out and log back in\n• Clear your browser cache\n• Contact support if login issues persist';
    }
    
    return '• Try the operation again\n• Restart the application\n• Contact support if the error continues';
  }

  static Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
    BuildContext? buildContext,
    bool showToUser = true,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context,
        showToUser: showToUser,
        buildContext: buildContext,
      );
      return fallbackValue;
    }
  }

  static Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
    IconData icon = Icons.error_outline,
    Color color = Colors.red,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SecurityServiceException implements Exception {
  final String message;
  final String userMessage;
  final String? code;
  final dynamic originalError;

  SecurityServiceException(
    this.message, {
    required this.userMessage,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'SecurityServiceException: $message';
}

class NetworkException extends SecurityServiceException {
  NetworkException(String message, {String? code, dynamic originalError})
      : super(
          message,
          userMessage: 'Network connection failed. Please check your internet connection.',
          code: code,
          originalError: originalError,
        );
}

class AuthenticationException extends SecurityServiceException {
  AuthenticationException(String message, {String? code, dynamic originalError})
      : super(
          message,
          userMessage: 'Authentication failed. Please log in again.',
          code: code,
          originalError: originalError,
        );
}

class PermissionException extends SecurityServiceException {
  PermissionException(String message, {String? code, dynamic originalError})
      : super(
          message,
          userMessage: 'Permission denied. Please contact your administrator.',
          code: code,
          originalError: originalError,
        );
}

class ServiceUnavailableException extends SecurityServiceException {
  ServiceUnavailableException(String message, {String? code, dynamic originalError})
      : super(
          message,
          userMessage: 'Service is temporarily unavailable. Please try again later.',
          code: code,
          originalError: originalError,
        );
}

class ValidationException extends SecurityServiceException {
  ValidationException(String message, {String? code, dynamic originalError})
      : super(
          message,
          userMessage: 'Invalid input provided. Please check your data.',
          code: code,
          originalError: originalError,
        );
}
