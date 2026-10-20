class Violation {
  final String id;
  final String inspectionNumber;
  final String siteName;
  final String requirement;
  final String? observation;
  final String? correctiveAction;
  final String status;
  final DateTime? dueDate;
  final bool isResolved;

  Violation({
    required this.id,
    required this.inspectionNumber,
    required this.siteName,
    required this.requirement,
    this.observation,
    this.correctiveAction,
    required this.status,
    this.dueDate,
    required this.isResolved,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: json['id'],
      inspectionNumber: json['inspectionNumber'],
      siteName: json['siteName'],
      requirement: json['requirement'],
      observation: json['observation'],
      correctiveAction: json['correctiveAction'],
      status: json['status'],
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate']),
      isResolved: json['isResolved'],
    );
  }
}