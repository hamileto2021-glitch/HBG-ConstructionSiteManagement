import '../../../../../core/config/api_config.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../models/document.dart';
import '../models/document_version.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class DocumentRepository {
  DocumentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ComplianceDocument>> getAll() async {
    final response = await _apiClient.getList('/Documents');

    return response
        .map((e) => ComplianceDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ComplianceDocument> getById(String documentId) async {
    final response = await _apiClient.get('/Documents/$documentId');
    return ComplianceDocument.fromJson(response);
  }

  Future<ComplianceDocument> create({
    required String documentNumber,
    required String name,
    required DocumentType documentType,

    String? drawingNumber,
    String? sheetNumber,
    DrawingDiscipline? discipline,
    DrawingStatus? drawingStatus,
    String? currentRevision,

    required String fileName,
    required String storagePath,
    String? contentType,
    required int fileSizeBytes,

    String? constructionSiteId,
    String? projectId,
    String? employeeId,
    String? relatedEntityId,
    String? relatedEntityType,

    DateTime? issueDate,
    DateTime? expiryDate,

    bool isConfidential = false,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/Documents',
      body: {
        'documentNumber': documentNumber,
        'name': name,
        'documentType': documentType.name,

        'drawingNumber': drawingNumber,
        'sheetNumber': sheetNumber,
        'discipline': discipline?.name,
        'drawingStatus': drawingStatus?.name,
        'currentRevision': currentRevision,

        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,

        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'employeeId': employeeId,
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,

        'issueDate': issueDate?.toIso8601String().split('T').first,
        'expiryDate': expiryDate?.toIso8601String().split('T').first,

        'isConfidential': isConfidential,
        'description': description,
      },
    );

    return ComplianceDocument.fromJson(response);
  }

  Future<ComplianceDocument> update({
    required String documentId,
    required String documentNumber,
    required String name,
    required DocumentType documentType,

    String? drawingNumber,
    String? sheetNumber,
    DrawingDiscipline? discipline,
    DrawingStatus? drawingStatus,
    String? currentRevision,

    required String fileName,
    required String storagePath,
    String? contentType,
    required int fileSizeBytes,

    String? constructionSiteId,
    String? projectId,
    String? employeeId,
    String? relatedEntityId,
    String? relatedEntityType,

    DateTime? issueDate,
    DateTime? expiryDate,

    bool isConfidential = false,
    String? description,
  }) async {
    final response = await _apiClient.put(
      '/Documents/$documentId',
      body: {
        'documentNumber': documentNumber,
        'name': name,
        'documentType': documentType.name,

        'drawingNumber': drawingNumber,
        'sheetNumber': sheetNumber,
        'discipline': discipline?.name,
        'drawingStatus': drawingStatus?.name,
        'currentRevision': currentRevision,

        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,

        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'employeeId': employeeId,
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,

        'issueDate': issueDate?.toIso8601String().split('T').first,
        'expiryDate': expiryDate?.toIso8601String().split('T').first,

        'isConfidential': isConfidential,
        'description': description,
      },
    );

    return ComplianceDocument.fromJson(response);
  }

  Future<List<DocumentVersion>> getVersions(String documentId) async {
    final response = await _apiClient.getList(
      '/Documents/$documentId/versions',
    );

    return response
        .map((e) => DocumentVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentVersion> createVersion({
    required String documentId,
    required String fileName,
    required String storagePath,
    String? contentType,
    required int fileSizeBytes,
    String? revisionNotes,
  }) async {
    final response = await _apiClient.post(
      '/Documents/$documentId/versions',
      body: {
        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,
        'revisionNotes': revisionNotes,
      },
    );

    return DocumentVersion.fromJson(response);
  }

  Future<DocumentVersion> uploadVersion({
    required String documentId,
    required PlatformFile file,
    String? revisionNotes,
  }) async {
    final storage = SecureStorageService();

    final token = await storage.getAccessToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.endpoint(
          '/Documents/$documentId/upload-version',
        ),
      ),
    );

    request.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['revisionNotes'] = revisionNotes ?? '';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ),
    );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(body, statusCode: response.statusCode);
    }

    return DocumentVersion.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }
}