import 'package:flutter/material.dart';

import '../data/equipment_repository.dart';
import '../data/models/equipment_model.dart';
import 'equipment_form_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final EquipmentRepository _repository = EquipmentRepository();

  bool _loading = true;
  List<EquipmentModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final result = await _repository.getAll();

      if (mounted) {
        setState(() {
          _items = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: const Text(
          'Are you sure you want to delete this equipment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    try {
      await _repository.delete(id);
      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EquipmentFormScreen(),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Register'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 150),
            Icon(Icons.precision_manufacturing,
                size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No equipment registered',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        )
            : ListView.builder(
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final item = _items[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(item.category.characters.first),
                ),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(item.equipmentCode),
                    Text(item.category),
                    if (item.manufacturer != null)
                      Text(item.manufacturer!),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => _delete(item.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}