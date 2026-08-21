import 'package:csm_app/core/network/api_client.dart';

import '../models/vendor.dart';

class VendorRepository {
  VendorRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Vendor>> getAll({
    bool? isActive,
  }) async {
    final queryParameters = <String, String>{};

    if (isActive != null) {
      queryParameters['isActive'] = isActive.toString();
    }

    final response = await _apiClient.getList(
      '/Vendors',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => Vendor.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Vendor> getById(String vendorId) async {
    final response = await _apiClient.get(
      '/Vendors/$vendorId',
    );

    return Vendor.fromJson(response);
  }

  Future<Vendor> create({
    required String vendorCode,
    required String name,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? taxIdentificationNumber,
    String? registrationNumber,
    String? bankName,
    String? bankAccountNumber,
    String? address,
    required bool isActive,
  }) async {
    final response = await _apiClient.post(
      '/Vendors',
      body: <String, dynamic>{
        'vendorCode': vendorCode,
        'name': name,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'taxIdentificationNumber':
            taxIdentificationNumber,
        'registrationNumber': registrationNumber,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'address': address,
        'isActive': isActive,
      },
    );

    return Vendor.fromJson(response);
  }

  Future<Vendor> update({
    required String vendorId,
    required String vendorCode,
    required String name,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? taxIdentificationNumber,
    String? registrationNumber,
    String? bankName,
    String? bankAccountNumber,
    String? address,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/Vendors/$vendorId',
      body: <String, dynamic>{
        'vendorCode': vendorCode,
        'name': name,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'taxIdentificationNumber':
            taxIdentificationNumber,
        'registrationNumber': registrationNumber,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'address': address,
        'isActive': isActive,
      },
    );

    return Vendor.fromJson(response);
  }
}
