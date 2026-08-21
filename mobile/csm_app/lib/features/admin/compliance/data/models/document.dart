enum DocumentType {
  permit,
  drawing,
  contract,
  safety,
  qaqc,
  manual,
  other,
}

extension DocumentTypeX on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.permit:
        return 'Permit';
      case DocumentType.drawing:
        return 'Drawing';
      case DocumentType.contract:
        return 'Contract';
      case DocumentType.safety:
        return 'Safety';
      case DocumentType.qaqc:
        return 'QA/QC';
      case DocumentType.manual:
        return 'Manual';
      case DocumentType.other:
        return 'Other';
    }
  }

  static DocumentType fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'permit':
      case '0':
        return DocumentType.permit;

      case 'drawing':
      case '1':
        return DocumentType.drawing;

      case 'contract':
      case '2':
        return DocumentType.contract;

      case 'safety':
      case '3':
        return DocumentType.safety;

      case 'qaqc':
      case 'qa/qc':
      case '4':
        return DocumentType.qaqc;

      case 'manual':
      case '5':
        return DocumentType.manual;

      default:
        return DocumentType.other;
    }
  }
}

class ComplianceDocument {
  const ComplianceDocument({
    required this.id,
    required this.companyId,
    required this.documentNumber,
    required this.name,
    required this.documentType,
    required this.fileName,
    required this.storagePath,
    this.contentType,
    required this.fileSizeBytes,
    this.constructionSiteId,
    this.projectId,
    this.employeeId,
    this.relatedEntityId,
    this.relatedEntityType,
    this.issueDate,
    this.expiryDate,
    required this.isConfidential,
    this.description,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String documentNumber;
  final String name;
  final DocumentType documentType;
  final String fileName;
  final String storagePath;
  final String? contentType;
  final int fileSizeBytes;
  final String? constructionSiteId;
  final String? projectId;
  final String? employeeId;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final bool isConfidential;
  final String? description;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory ComplianceDocument.fromJson(
      Map<String, dynamic> json,
      ) {
    DateTime? parse(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return ComplianceDocument(
      id: json['id'],
      companyId: json['companyId'],
      documentNumber: json['documentNumber'],
      name: json['name'],
      documentType:
      DocumentTypeX.fromJson(json['documentType']),
      fileName: json['fileName'],
      storagePath: json['storagePath'],
      contentType: json['contentType'],
      fileSizeBytes: json['fileSizeBytes'],
      constructionSiteId: json['constructionSiteId'],
      projectId: json['projectId'],
      employeeId: json['employeeId'],
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
      issueDate: parse(json['issueDate']),
      expiryDate: parse(json['expiryDate']),
      isConfidential: json['isConfidential'],
      description: json['description'],
      createdAtUtc:
      DateTime.parse(json['createdAtUtc']),
      updatedAtUtc: parse(json['updatedAtUtc']),
    );
  }
}