import 'package:flutter/material.dart';

import '../data/models/vendor.dart';
import '../data/repositories/vendor_repository.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({
    super.key,
    required this.vendorId,
    required this.repository,
  });

  final String vendorId;
  final VendorRepository repository;

  @override
  State<VendorDetailScreen> createState() =>
      _VendorDetailScreenState();
}

class _VendorDetailScreenState
    extends State<VendorDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _vendorCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _registrationNumberController =
      TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController =
      TextEditingController();
  final _addressController = TextEditingController();

  Vendor? _vendor;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isActive = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  @override
  void dispose() {
    _vendorCodeController.dispose();
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    _registrationNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVendor() async {
    try {
      final vendor =
          await widget.repository.getById(widget.vendorId);

      if (!mounted) {
        return;
      }

      _vendor = vendor;
      _vendorCodeController.text = vendor.vendorCode;
      _nameController.text = vendor.name;
      _contactPersonController.text =
          vendor.contactPerson ?? '';
      _phoneNumberController.text =
          vendor.phoneNumber ?? '';
      _emailController.text = vendor.email ?? '';
      _taxIdController.text =
          vendor.taxIdentificationNumber ?? '';
      _registrationNumberController.text =
          vendor.registrationNumber ?? '';
      _bankNameController.text =
          vendor.bankName ?? '';
      _bankAccountNumberController.text =
          vendor.bankAccountNumber ?? '';
      _addressController.text = vendor.address ?? '';
      _isActive = vendor.isActive;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.update(
        vendorId: widget.vendorId,
        vendorCode: _vendorCodeController.text.trim(),
        name: _nameController.text.trim(),
        contactPerson:
            _optionalValue(_contactPersonController),
        phoneNumber:
            _optionalValue(_phoneNumberController),
        email: _optionalValue(_emailController),
        taxIdentificationNumber:
            _optionalValue(_taxIdController),
        registrationNumber:
            _optionalValue(
              _registrationNumberController,
            ),
        bankName: _optionalValue(_bankNameController),
        bankAccountNumber:
            _optionalValue(
              _bankAccountNumberController,
            ),
        address: _optionalValue(_addressController),
        isActive: _isActive,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update vendor: $error',
          ),
        ),
      );
    }
  }

  String? _optionalValue(
    TextEditingController controller,
  ) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Details'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadVendor,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _InfoRow(
            label: 'Vendor ID',
            value: _vendor!.id,
          ),
          _InfoRow(
            label: 'Company ID',
            value: _vendor!.companyId,
          ),
          _InfoRow(
            label: 'Created',
            value: _formatDateTime(
              _vendor!.createdAtUtc,
            ),
          ),
          if (_vendor!.updatedAtUtc != null)
            _InfoRow(
              label: 'Updated',
              value: _formatDateTime(
                _vendor!.updatedAtUtc!,
              ),
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _vendorCodeController,
            decoration: const InputDecoration(
              labelText: 'Vendor Code',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Vendor code is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactPersonController,
            decoration: const InputDecoration(
              labelText: 'Contact Person',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _taxIdController,
            decoration: const InputDecoration(
              labelText: 'Tax Identification Number',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Registration Number',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankAccountNumberController,
            decoration: const InputDecoration(
              labelText: 'Bank Account Number',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _isActive,
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Changes',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return value.toLocal().toString();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
