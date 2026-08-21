enum SiteStatus {
  planning,
  active,
  onHold,
  completed,
  closed,
}

extension SiteStatusX on SiteStatus {
  String get displayName {
    switch (this) {
      case SiteStatus.planning:
        return 'Planning';
      case SiteStatus.active:
        return 'Active';
      case SiteStatus.onHold:
        return 'On Hold';
      case SiteStatus.completed:
        return 'Completed';
      case SiteStatus.closed:
        return 'Closed';
    }
  }

  static SiteStatus fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'planning':
      case '0':
        return SiteStatus.planning;
      case 'active':
      case '1':
        return SiteStatus.active;
      case 'onhold':
      case 'on_hold':
      case 'on hold':
      case '2':
        return SiteStatus.onHold;
      case 'completed':
      case '3':
        return SiteStatus.completed;
      case 'closed':
      case '4':
        return SiteStatus.closed;
      default:
        return SiteStatus.planning;
    }
  }
}

class Site {
  const Site({
    required this.id,
    required this.companyId,
    required this.siteCode,
    required this.name,
    this.description,
    this.businessUnitId,
    this.address,
    this.city,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.status,
    required this.isActive,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String siteCode;
  final String name;
  final String? description;
  final String? businessUnitId;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final double? latitude;
  final double? longitude;
  final double? geofenceRadiusMeters;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final SiteStatus status;
  final bool isActive;
  final DateTime createdAtUtc;

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      siteCode: json['siteCode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      businessUnitId: json['businessUnitId'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geofenceRadiusMeters:
      (json['geofenceRadiusMeters'] as num?)?.toDouble(),
      plannedStartDate: _parseDate(json['plannedStartDate']),
      plannedEndDate: _parseDate(json['plannedEndDate']),
      actualStartDate: _parseDate(json['actualStartDate']),
      actualEndDate: _parseDate(json['actualEndDate']),
      status: SiteStatusX.fromJson(json['status']),
      isActive: json['isActive'] as bool,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}