import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/backup_info.dart';
import '../data/repositories/backup_repository.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.repository,
  });

  final BackupRepository repository;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<BackupInfo> _backups = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await widget.repository.getBackups();

      if (!mounted) return;

      setState(() {
        _backups = data;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _creating = true);

    try {
      final file = await widget.repository.createBackup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: $file'),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }
  Future<void> _restoreBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'File picker will be connected after backend build.',
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd MMM yyyy  HH:mm').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Backup'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Backup'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _creating ? null : _createBackup,
            icon: _creating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.backup),
            label: Text(
              _creating ? 'Creating...' : 'Create Backup',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _backups.isEmpty
          ? const Center(
        child: Text('No backup files found.'),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _backups.length,
        separatorBuilder: (context, index) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final backup = _backups[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.folder_zip),
              ),
              title: Text(
                backup.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_formatDate(backup.createdAtUtc)}\n${backup.formattedSize}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(
                  Icons.restore,
                  color: Colors.green,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Restore upload will be enabled after backend build.',
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}