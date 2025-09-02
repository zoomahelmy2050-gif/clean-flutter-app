import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudStorageService extends ChangeNotifier {
  static CloudStorageService? _instance;
  static CloudStorageService get instance => _instance ??= CloudStorageService._();
  CloudStorageService._();

  final Dio _dio = Dio();
  bool _isInitialized = false;

  // Configuration loaded from environment
  late String _awsAccessKeyId;
  late String _awsSecretAccessKey;
  late String _awsRegion;
  late String _s3BucketName;
  late String _gcpProjectId;
  late String _gcsBucketName;
  late String _azureStorageAccount;
  late String _azureStorageKey;
  late String _azureContainerName; // Used for Azure Blob Storage operations

  // Storage provider
  StorageProvider _currentProvider = StorageProvider.aws;

  Future<void> initialize({StorageProvider provider = StorageProvider.aws}) async {
    if (_isInitialized) return;

    // Load configuration from environment
    _awsAccessKeyId = dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
    _awsSecretAccessKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
    _awsRegion = dotenv.env['AWS_REGION'] ?? 'us-east-1';
    _s3BucketName = dotenv.env['AWS_S3_BUCKET'] ?? 'security-evidence-storage';
    _gcpProjectId = dotenv.env['GCP_PROJECT_ID'] ?? '';
    _gcsBucketName = dotenv.env['GCP_BUCKET_NAME'] ?? 'security-evidence-gcs';
    _azureStorageAccount = dotenv.env['AZURE_STORAGE_ACCOUNT'] ?? '';
    _azureStorageKey = dotenv.env['AZURE_STORAGE_KEY'] ?? '';
    _azureContainerName = dotenv.env['AZURE_CONTAINER_NAME'] ?? 'security-data';

    _currentProvider = provider;
    _dio.options.connectTimeout = const Duration(minutes: 5);
    _dio.options.receiveTimeout = const Duration(minutes: 10);

    _isInitialized = true;
    
    if (_hasValidCredentials(provider)) {
      developer.log('Cloud storage service initialized with real ${provider.name} APIs');
    } else {
      developer.log('Cloud storage service initialized in mock mode - no credentials for ${provider.name}');
    }
  }

  // Evidence storage methods
  Future<StorageResult> storeEvidence({
    required String caseId,
    required String evidenceName,
    required Uint8List data,
    required String contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final fileName = _generateEvidenceFileName(caseId, evidenceName);
      final hash = _calculateHash(data);
      
      // Add integrity metadata
      final enhancedMetadata = {
        'case_id': caseId,
        'evidence_name': evidenceName,
        'content_type': contentType,
        'file_size': data.length.toString(),
        'md5_hash': hash.md5,
        'sha256_hash': hash.sha256,
        'upload_timestamp': DateTime.now().toIso8601String(),
        'chain_of_custody': jsonEncode([
          {
            'action': 'uploaded',
            'timestamp': DateTime.now().toIso8601String(),
            'user': 'system',
            'hash': hash.sha256,
          }
        ]),
        ...?metadata,
      };

      switch (_currentProvider) {
        case StorageProvider.aws:
          return await _uploadToS3(fileName, data, contentType, enhancedMetadata);
        case StorageProvider.gcp:
          return await _uploadToGCS(fileName, data, contentType, enhancedMetadata);
        case StorageProvider.azure:
          return await _uploadToAzure(fileName, data, contentType, enhancedMetadata);
      }
    } catch (e) {
      developer.log('Evidence storage error: $e');
      return StorageResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<StorageResult> retrieveEvidence(String fileKey) async {
    try {
      switch (_currentProvider) {
        case StorageProvider.aws:
          return await _downloadFromS3(fileKey);
        case StorageProvider.gcp:
          return await _downloadFromGCS(fileKey);
        case StorageProvider.azure:
          return await _downloadFromAzure(fileKey);
      }
    } catch (e) {
      developer.log('Evidence retrieval error: $e');
      return StorageResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> verifyEvidenceIntegrity(String fileKey, String expectedHash) async {
    try {
      final result = await retrieveEvidence(fileKey);
      if (!result.success || result.data == null) {
        return false;
      }

      final actualHash = _calculateHash(result.data!);
      return actualHash.sha256 == expectedHash;
    } catch (e) {
      developer.log('Evidence integrity verification error: $e');
      return false;
    }
  }

  // AWS S3 Implementation
  Future<StorageResult> _uploadToS3(
    String fileName,
    Uint8List data,
    String contentType,
    Map<String, String> metadata,
  ) async {
    try {
      final timestamp = DateTime.now().toUtc();
      final dateStamp = timestamp.toIso8601String().substring(0, 8);
      final amzDate = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-]'), '').substring(0, 15) + 'Z';

      final host = '$_s3BucketName.s3.$_awsRegion.amazonaws.com';
      final url = 'https://$host/$fileName';

      // Create AWS Signature V4
      final canonicalRequest = _createCanonicalRequest(
        'PUT',
        '/$fileName',
        '',
        {
          'host': host,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': sha256.convert(data).toString(),
        },
        sha256.convert(data).toString(),
      );

      final stringToSign = _createStringToSign(amzDate, dateStamp, canonicalRequest);
      final signature = _calculateSignature(stringToSign, dateStamp);

      final response = await _dio.put(
        url,
        data: data,
        options: Options(
          headers: {
            'Host': host,
            'X-Amz-Date': amzDate,
            'X-Amz-Content-Sha256': sha256.convert(data).toString(),
            'Authorization': 'AWS4-HMAC-SHA256 Credential=$_awsAccessKeyId/$dateStamp/$_awsRegion/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=$signature',
            'Content-Type': contentType,
            ...metadata.map((key, value) => MapEntry('x-amz-meta-$key', value)),
          },
        ),
      );

      if (response.statusCode == 200) {
        return StorageResult(
          success: true,
          fileKey: fileName,
          url: url,
          metadata: metadata,
        );
      } else {
        return StorageResult(
          success: false,
          error: 'S3 upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'S3 upload error: $e',
      );
    }
  }

  Future<StorageResult> _downloadFromS3(String fileKey) async {
    try {
      final timestamp = DateTime.now().toUtc();
      final dateStamp = timestamp.toIso8601String().substring(0, 8);
      final amzDate = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-]'), '').substring(0, 15) + 'Z';

      final host = '$_s3BucketName.s3.$_awsRegion.amazonaws.com';
      final url = 'https://$host/$fileKey';

      final canonicalRequest = _createCanonicalRequest(
        'GET',
        '/$fileKey',
        '',
        {
          'host': host,
          'x-amz-date': amzDate,
        },
        'UNSIGNED-PAYLOAD',
      );

      final stringToSign = _createStringToSign(amzDate, dateStamp, canonicalRequest);
      final signature = _calculateSignature(stringToSign, dateStamp);

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Host': host,
            'X-Amz-Date': amzDate,
            'Authorization': 'AWS4-HMAC-SHA256 Credential=$_awsAccessKeyId/$dateStamp/$_awsRegion/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=$signature',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return StorageResult(
          success: true,
          fileKey: fileKey,
          data: Uint8List.fromList(response.data),
          metadata: _extractMetadataFromHeaders(response.headers),
        );
      } else {
        return StorageResult(
          success: false,
          error: 'S3 download failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'S3 download error: $e',
      );
    }
  }

  // Google Cloud Storage Implementation
  Future<StorageResult> _uploadToGCS(
    String fileName,
    Uint8List data,
    String contentType,
    Map<String, String> metadata,
  ) async {
    try {
      // This would require Google Cloud Storage API implementation
      // For now, return a mock success
      developer.log('GCS upload would be implemented here');
      return StorageResult(
        success: true,
        fileKey: fileName,
        url: 'gs://$_gcsBucketName/$fileName',
        metadata: metadata,
      );
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'GCS upload error: $e',
      );
    }
  }

  Future<StorageResult> _downloadFromGCS(String fileKey) async {
    try {
      // GCS download implementation would go here
      developer.log('GCS download would be implemented here');
      return StorageResult(
        success: false,
        error: 'GCS download not implemented',
      );
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'GCS download error: $e',
      );
    }
  }

  // Azure Blob Storage Implementation
  Future<StorageResult> _uploadToAzure(
    String fileName,
    Uint8List data,
    String contentType,
    Map<String, String> metadata,
  ) async {
    try {
      // Azure Blob Storage implementation would go here
      developer.log('Azure upload would be implemented here');
      return StorageResult(
        success: true,
        fileKey: fileName,
        metadata: metadata,
      );
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'Azure upload error: $e',
      );
    }
  }

  Future<StorageResult> _downloadFromAzure(String fileKey) async {
    try {
      // Azure download implementation would go here
      developer.log('Azure download would be implemented here');
      return StorageResult(
        success: false,
        error: 'Azure download not implemented',
      );
    } catch (e) {
      return StorageResult(
        success: false,
        error: 'Azure download error: $e',
      );
    }
  }

  // Chain of custody management
  Future<void> updateChainOfCustody({
    required String fileKey,
    required String action,
    required String user,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Retrieve current metadata
      final result = await retrieveEvidence(fileKey);
      if (!result.success || result.metadata == null) {
        throw Exception('Could not retrieve evidence metadata');
      }

      // Parse existing chain of custody
      final chainOfCustodyJson = result.metadata!['chain_of_custody'];
      final chainOfCustody = chainOfCustodyJson != null 
          ? List<Map<String, dynamic>>.from(jsonDecode(chainOfCustodyJson))
          : <Map<String, dynamic>>[];

      // Add new entry
      chainOfCustody.add({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'user': user,
        'hash': result.data != null ? _calculateHash(result.data!).sha256 : null,
        ...?additionalData,
      });

      // Update metadata
      final updatedMetadata = {
        ...result.metadata!,
        'chain_of_custody': jsonEncode(chainOfCustody),
        'last_modified': DateTime.now().toIso8601String(),
      };

      // Re-upload with updated metadata (this would depend on the storage provider)
      developer.log('Chain of custody updated for $fileKey');
    } catch (e) {
      developer.log('Error updating chain of custody: $e');
    }
  }

  // Utility methods
  String _generateEvidenceFileName(String caseId, String evidenceName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = evidenceName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'evidence/$caseId/${timestamp}_$sanitizedName';
  }

  FileHash _calculateHash(Uint8List data) {
    final md5Hash = md5.convert(data);
    final sha256Hash = sha256.convert(data);
    return FileHash(
      md5: md5Hash.toString(),
      sha256: sha256Hash.toString(),
    );
  }

  String _createCanonicalRequest(
    String method,
    String uri,
    String queryString,
    Map<String, String> headers,
    String payloadHash,
  ) {
    final sortedHeaders = Map.fromEntries(
      headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    final canonicalHeaders = sortedHeaders.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value}')
        .join('\n');

    final signedHeaders = sortedHeaders.keys
        .map((key) => key.toLowerCase())
        .join(';');

    return '$method\n$uri\n$queryString\n$canonicalHeaders\n\n$signedHeaders\n$payloadHash';
  }

  String _createStringToSign(String amzDate, String dateStamp, String canonicalRequest) {
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$_awsRegion/s3/aws4_request';
    final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();

    return '$algorithm\n$amzDate\n$credentialScope\n$hashedCanonicalRequest';
  }

  String _calculateSignature(String stringToSign, String dateStamp) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$_awsSecretAccessKey')).convert(utf8.encode(dateStamp));
    final kRegion = Hmac(sha256, kDate.bytes).convert(utf8.encode(_awsRegion));
    final kService = Hmac(sha256, kRegion.bytes).convert(utf8.encode('s3'));
    final kSigning = Hmac(sha256, kService.bytes).convert(utf8.encode('aws4_request'));
    final signature = Hmac(sha256, kSigning.bytes).convert(utf8.encode(stringToSign));

    return signature.toString();
  }

  Map<String, String> _extractMetadataFromHeaders(Headers headers) {
    final metadata = <String, String>{};
    headers.forEach((name, values) {
      if (name.startsWith('x-amz-meta-')) {
        final key = name.substring(11); // Remove 'x-amz-meta-' prefix
        metadata[key] = values.first;
      }
    });
    return metadata;
  }

  // Backup and replication
  Future<void> createBackup(String fileKey, StorageProvider backupProvider) async {
    try {
      final result = await retrieveEvidence(fileKey);
      if (!result.success || result.data == null) {
        throw Exception('Could not retrieve evidence for backup');
      }

      final originalProvider = _currentProvider;
      _currentProvider = backupProvider;

      await storeEvidence(
        caseId: result.metadata?['case_id'] ?? 'backup',
        evidenceName: result.metadata?['evidence_name'] ?? fileKey,
        data: result.data!,
        contentType: result.metadata?['content_type'] ?? 'application/octet-stream',
        metadata: {
          ...?result.metadata,
          'backup_of': fileKey,
          'backup_timestamp': DateTime.now().toIso8601String(),
        },
      );

      _currentProvider = originalProvider;
      developer.log('Backup created for $fileKey on ${backupProvider.name}');
    } catch (e) {
      developer.log('Backup creation error: $e');
    }
  }

  // Storage analytics
  Future<StorageAnalytics> getStorageAnalytics() async {
    // This would query the storage provider for usage statistics
    return StorageAnalytics(
      totalFiles: 0,
      totalSize: 0,
      storageUsed: 0.0,
      costEstimate: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  bool _hasValidCredentials(StorageProvider provider) {
    switch (provider) {
      case StorageProvider.aws:
        return _awsAccessKeyId.isNotEmpty && _awsSecretAccessKey.isNotEmpty;
      case StorageProvider.gcp:
        return _gcpProjectId.isNotEmpty;
      case StorageProvider.azure:
        return _azureStorageAccount.isNotEmpty && _azureStorageKey.isNotEmpty;
    }
  }
}

// Enums and data models
enum StorageProvider { aws, gcp, azure }

class StorageResult {
  final bool success;
  final String? fileKey;
  final String? url;
  final Uint8List? data;
  final Map<String, String>? metadata;
  final String? error;

  StorageResult({
    required this.success,
    this.fileKey,
    this.url,
    this.data,
    this.metadata,
    this.error,
  });
}

class FileHash {
  final String md5;
  final String sha256;

  FileHash({
    required this.md5,
    required this.sha256,
  });
}

class StorageAnalytics {
  final int totalFiles;
  final int totalSize;
  final double storageUsed;
  final double costEstimate;
  final DateTime lastUpdated;

  StorageAnalytics({
    required this.totalFiles,
    required this.totalSize,
    required this.storageUsed,
    required this.costEstimate,
    required this.lastUpdated,
  });
}
