import '../../../../../core/network/api_client.dart';
import '../models/document.dart';
import '../models/document_version.dart';

class DocumentRepository {
  DocumentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ComplianceDocument>> getAll() async {
    final response = await _apiClient.getList('/Documents');

    return response
        .map(
          (e) => ComplianceDocument.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<ComplianceDocument> getById(
      String documentId,
      ) async {
    final response =
    await _apiClient.get('/Documents/$documentId');

    return ComplianceDocument.fromJson(response);
  }

  Future<ComplianceDocument> create({
    required String documentNumber,
    required String name,
    required DocumentType documentType,
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
        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'employeeId': employeeId,
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,
        'issueDate':
        issueDate?.toIso8601String().split('T').first,
        'expiryDate':
        expiryDate?.toIso8601String().split('T').first,
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
        'fileName': fileName,
        'storagePath': storagePath,
        'contentType': contentType,
        'fileSizeBytes': fileSizeBytes,
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'employeeId': employeeId,
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,
        'issueDate':
        issueDate?.toIso8601String().split('T').first,
        'expiryDate':
        expiryDate?.toIso8601String().split('T').first,
        'isConfidential': isConfidential,
        'description': description,
      },
    );

    return ComplianceDocument.fromJson(response);
  }
  Future<List<DocumentVersion>> getVersions(
      String documentId,
      ) async {
    final response = await _apiClient.getList(
      '/documents/$documentId/versions',
    );

    return response
        .map(
          (e) => DocumentVersion.fromJson(
        e as Map<String, dynamic>,
      ),
    )
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
      '/documents/$documentId/versions',
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
}
