import 'package:flutter/material.dart';

import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import 'user_create_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({
    super.key,
    required this.repository,
  });

  final UserRepository repository;

  @override
  State<UserListScreen> createState() =>
      _UserListScreenState();
}

class _UserListScreenState
    extends State<UserListScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _users = users;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => UserCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadUsers();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.people_outline,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text('No users found.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailScreen(
                    userId: _users[index].id,
                    repository: widget.repository,
                  ),
                ),
              );

              await _loadUsers();
            },
            child: _UserCard(
              user: _users[index],
            ),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
  });

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(
                user.firstName.substring(0, 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(user.email),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: user.roles
                        .map(
                          (role) => Chip(
                        label: Text(role),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  user.isActive
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: user.isActive
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(height: 4),
                Text(
                  user.isActive
                      ? 'Active'
                      : 'Inactive',
                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}