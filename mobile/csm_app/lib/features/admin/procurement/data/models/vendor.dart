class Vendor {
  const Vendor({
    required this.id,
    required this.companyId,
    required this.vendorCode,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.taxIdentificationNumber,
    this.registrationNumber,
    this.bankName,
    this.bankAccountNumber,
    this.address,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String vendorCode;
  final String name;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? taxIdentificationNumber;
  final String? registrationNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? address;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      vendorCode: json['vendorCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactPerson:
          json['contactPerson'] as String?,
      phoneNumber:
          json['phoneNumber'] as String?,
      email: json['email'] as String?,
      taxIdentificationNumber:
          json['taxIdentificationNumber'] as String?,
      registrationNumber:
          json['registrationNumber'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountNumber:
          json['bankAccountNumber'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc:
          json['updatedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['updatedAtUtc'] as String,
                ),
    );
  }
}
