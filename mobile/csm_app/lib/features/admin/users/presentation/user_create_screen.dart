import 'package:flutter/material.dart';

import '../data/repositories/user_repository.dart';
import '../../../../../core/storage/secure_storage_service.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({
    super.key,
    required this.repository,
  });

  final UserRepository repository;

  @override
  State<UserCreateScreen> createState() =>
      _UserCreateScreenState();
}

class _UserCreateScreenState
    extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _storage = SecureStorageService();

  String? _companyId;
  bool _saving = false;

  final List<String> _roles = [];

  final List<String> _availableRoles = const [
    'SuperAdmin',
    'CompanyAdmin',
    'SiteManager',
    'Accountant',
    'HROfficer',
    'Supervisor',
    'Employee',
  ];

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final companyId = await _storage.getCompanyId();

    if (!mounted) return;

    setState(() {
      _companyId = companyId;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one role.'),
        ),
      );
      return;
    }

    if (_companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Company not found. Please sign in again.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        companyId: _companyId!,
        email: _email.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        temporaryPassword: _password.text,
        roles: _roles,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _email,
              keyboardType:
              TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Temporary Password',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.length < 6
                  ? 'Minimum 6 characters'
                  : null,
            ),
            const SizedBox(height: 24),

            Text(
              'Roles',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),

            ..._availableRoles.map(
                  (role) => CheckboxListTile(
                value: _roles.contains(role),
                title: Text(role),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _roles.add(role);
                    } else {
                      _roles.remove(role);
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Creating...'
                    : 'Create User',
              ),
            ),
          ],
        ),
      ),
    );
  }
}