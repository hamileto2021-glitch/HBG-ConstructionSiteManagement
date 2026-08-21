import 'package:flutter/material.dart';

import '../../../core/sync/sync_manager.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.roles,
    this.syncManager,
  });

  final String userName;
  final String userEmail;
  final Set<String> roles;
  final SyncManager? syncManager;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Welcome, $userName',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _buildAccessCard(context),
        const SizedBox(height: 16),
        _buildSyncCard(context),
      ],
    );
  }

  Widget _buildAccessCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authorized Access',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Your current roles determine which administration '
              'areas are available to you.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (role) => Chip(
                      avatar: const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                      ),
                      label: Text(role),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context) {
    if (syncManager == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.sync_disabled_outlined),
            title: Text('Synchronization'),
            subtitle: Text(
              'Synchronization service is not connected yet.',
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: syncManager!,
      builder: (context, _) {
        final status = syncManager!.status;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Synchronization',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed:
                          status.isSyncing
                              ? null
                              : () {
                                  syncManager!.synchronize();
                                },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync now'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _statusRow(
                  context,
                  'State',
                  status.state.name,
                ),
                _statusRow(
                  context,
                  'Pending operations',
                  status.pendingCount.toString(),
                ),
                _statusRow(
                  context,
                  'Failed operations',
                  status.failedCount.toString(),
                ),
                _statusRow(
                  context,
                  'Last successful sync',
                  status.lastSuccessfulSyncUtc
                          ?.toLocal()
                          .toString() ??
                      'Not synchronized yet',
                ),
                if (status.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    status.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
