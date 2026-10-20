class CreateWorkPermitRequest {
  const CreateWorkPermitRequest({
    required this.constructionSiteId,
    required this.permitNumber,
    required this.permitType,
    required this.name,
    required this.applicationDate,
    required this.issueDate,
    required this.expiryDate,
    this.projectId,
    this.issuingAuthority,
    this.status = 0,
    this.expiryAlertDays = 30,
    this.conditions,
    this.notes,
  });

  final String constructionSiteId;
  final String? projectId;

  final String permitNumber;
  final String permitType;
  final String name;

  final DateTime applicationDate;
  final DateTime issueDate;
  final DateTime expiryDate;

  final String? issuingAuthority;
  final int status;
  final int expiryAlertDays;
  final String? conditions;
  final String? notes;

  String _date(DateTime value) =>
      value.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'projectId': projectId,
      'permitNumber': permitNumber,
      'permitType': permitType,
      'name': name,
      'issuingAuthority': issuingAuthority,
      'applicationDate': _date(applicationDate),
      'issueDate': _date(issueDate),
      'expiryDate': _date(expiryDate),
      'status': status,
      'expiryAlertDays': expiryAlertDays,
      'conditions': conditions,
      'notes': notes,
    };
  }
}