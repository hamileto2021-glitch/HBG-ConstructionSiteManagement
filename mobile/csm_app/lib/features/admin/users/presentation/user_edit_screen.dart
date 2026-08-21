import 'package:flutter/material.dart';

import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';

class UserEditScreen extends StatefulWidget {
  const UserEditScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final UserRepository repository;

  @override
  State<UserEditScreen> createState() =>
      _UserEditScreenState();
}

class _UserEditScreenState
    extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;

  bool _saving = false;

  final List<String> _selectedRoles = [];

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

    _firstName = TextEditingController(
      text: widget.user.firstName,
    );

    _lastName = TextEditingController(
      text: widget.user.lastName,
    );

    _selectedRoles.addAll(widget.user.roles);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.update(
        userId: widget.user.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        employeeId: widget.user.employeeId,
      );

      await widget.repository.setRoles(
        userId: widget.user.id,
        roles: _selectedRoles.toSet().toList(),
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

  Future<void> _toggleActive() async {
    try {
      if (widget.user.isActive) {
        await widget.repository.deactivate(widget.user.id);
      } else {
        await widget.repository.activate(widget.user.id);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
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
                value: _selectedRoles.contains(role),
                title: Text(role),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          if (!_selectedRoles.contains(role)) {
                            _selectedRoles.add(role);
                          }
                        } else {
                          _selectedRoles.remove(role);
                        }
                      });
                    },
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _toggleActive,
              icon: Icon(
                widget.user.isActive
                    ? Icons.person_off
                    : Icons.person,
              ),
              label: Text(
                widget.user.isActive
                    ? 'Deactivate User'
                    : 'Activate User',
              ),
            ),
          ],
        ),
      ),
    );
  }
}