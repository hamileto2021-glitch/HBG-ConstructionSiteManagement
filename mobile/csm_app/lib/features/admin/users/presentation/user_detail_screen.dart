import 'package:flutter/material.dart';

import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import 'user_edit_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.repository,
  });

  final String userId;
  final UserRepository repository;

  @override
  State<UserDetailScreen> createState() =>
      _UserDetailScreenState();
}

class _UserDetailScreenState
    extends State<UserDetailScreen> {
  AppUser? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await widget.repository.getById(
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User')),
        body: Center(child: Text(_error!)),
      );
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              child: Text(
                user.firstName.substring(0, 1),
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              user.fullName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
          ),

          Center(child: Text(user.email)),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Status'),
                  trailing: Text(
                    user.isActive
                        ? 'Active'
                        : 'Inactive',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text(
                    'Must Change Password',
                  ),
                  trailing: Text(
                    user.mustChangePassword
                        ? 'Yes'
                        : 'No',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Last Login'),
                  trailing: Text(
                    user.lastLoginAtUtc == null
                        ? 'Never'
                        : user.lastLoginAtUtc!
                        .toLocal()
                        .toString()
                        .substring(0, 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Roles',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.roles
                .map(
                  (role) => Chip(label: Text(role)),
            )
                .toList(),
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () async {
              final updated =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => UserEditScreen(
                    user: user,
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true) {
                await _load();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit User'),
          ),
        ],
      ),
    );
  }
}