import 'package:flutter/material.dart';

import '../data/repositories/vendor_repository.dart';

class VendorCreateScreen extends StatefulWidget {
  const VendorCreateScreen({
    super.key,
    required this.repository,
  });

  final VendorRepository repository;

  @override
  State<VendorCreateScreen> createState() =>
      _VendorCreateScreenState();
}

class _VendorCreateScreenState
    extends State<VendorCreateScreen> {
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

  bool _isActive = true;
  bool _isSaving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
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
            'Failed to create vendor: $error',
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
        title: const Text('Create Vendor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Saving...' : 'Create Vendor',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
