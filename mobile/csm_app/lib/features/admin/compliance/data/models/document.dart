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

enum DrawingDiscipline {
  architectural,
  structural,
  civil,
  mechanical,
  electrical,
  plumbing,
  hvac,
  landscape,
  other,
}

extension DrawingDisciplineX on DrawingDiscipline {
  String get displayName {
    switch (this) {
      case DrawingDiscipline.architectural:
        return 'Architectural';
      case DrawingDiscipline.structural:
        return 'Structural';
      case DrawingDiscipline.civil:
        return 'Civil';
      case DrawingDiscipline.mechanical:
        return 'Mechanical';
      case DrawingDiscipline.electrical:
        return 'Electrical';
      case DrawingDiscipline.plumbing:
        return 'Plumbing';
      case DrawingDiscipline.hvac:
        return 'HVAC';
      case DrawingDiscipline.landscape:
        return 'Landscape';
      case DrawingDiscipline.other:
        return 'Other';
    }
  }

  static DrawingDiscipline? fromJson(dynamic value) {
    if (value == null) return null;

    switch (value.toString().toLowerCase()) {
      case 'architectural':
        return DrawingDiscipline.architectural;
      case 'structural':
        return DrawingDiscipline.structural;
      case 'civil':
        return DrawingDiscipline.civil;
      case 'mechanical':
        return DrawingDiscipline.mechanical;
      case 'electrical':
        return DrawingDiscipline.electrical;
      case 'plumbing':
        return DrawingDiscipline.plumbing;
      case 'hvac':
        return DrawingDiscipline.hvac;
      case 'landscape':
        return DrawingDiscipline.landscape;
      default:
        return DrawingDiscipline.other;
    }
  }
}

enum DrawingStatus {
  draft,
  issuedForReview,
  approved,
  issuedForConstruction,
  asBuilt,
  superseded,
}

extension DrawingStatusX on DrawingStatus {
  String get displayName {
    switch (this) {
      case DrawingStatus.draft:
        return 'Draft';
      case DrawingStatus.issuedForReview:
        return 'IFR';
      case DrawingStatus.approved:
        return 'Approved';
      case DrawingStatus.issuedForConstruction:
        return 'IFC';
      case DrawingStatus.asBuilt:
        return 'As-Built';
      case DrawingStatus.superseded:
        return 'Superseded';
    }
  }

  static DrawingStatus? fromJson(dynamic value) {
    if (value == null) return null;

    switch (value.toString().toLowerCase()) {
      case 'draft':
        return DrawingStatus.draft;
      case 'issuedforreview':
        return DrawingStatus.issuedForReview;
      case 'approved':
        return DrawingStatus.approved;
      case 'issuedforconstruction':
        return DrawingStatus.issuedForConstruction;
      case 'asbuilt':
        return DrawingStatus.asBuilt;
      case 'superseded':
        return DrawingStatus.superseded;
      default:
        return DrawingStatus.draft;
    }
  }
}

class ComplianceDocument {
  const ComplianceDocument({
    required this.id,
    required this.companyId,
    this.constructionSiteName,
    required this.documentNumber,
    required this.name,
    required this.documentType,

    this.drawingNumber,
    this.sheetNumber,
    this.discipline,
    this.drawingStatus,
    this.currentRevision,

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
  final String? constructionSiteName;
  final String documentNumber;
  final String name;
  final DocumentType documentType;

  // Drawing Management
  final String? drawingNumber;
  final String? sheetNumber;
  final DrawingDiscipline? discipline;
  final DrawingStatus? drawingStatus;
  final String? currentRevision;

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

  factory ComplianceDocument.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return ComplianceDocument(
      id: json['id'],
      companyId: json['companyId'],
      constructionSiteName: json['constructionSiteName'],
      documentNumber: json['documentNumber'],
      name: json['name'],
      documentType: DocumentTypeX.fromJson(json['documentType']),

      drawingNumber: json['drawingNumber'],
      sheetNumber: json['sheetNumber'],
      discipline: DrawingDisciplineX.fromJson(json['discipline']),
      drawingStatus: DrawingStatusX.fromJson(json['drawingStatus']),
      currentRevision: json['currentRevision'],

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

      createdAtUtc: DateTime.parse(json['createdAtUtc']),
      updatedAtUtc: parse(json['updatedAtUtc']),
    );
  }
}