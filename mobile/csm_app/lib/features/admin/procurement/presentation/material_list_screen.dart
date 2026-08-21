import 'package:flutter/material.dart' hide Material;

import '../data/models/material.dart';
import '../data/repositories/material_repository.dart';
import 'material_create_screen.dart';
import 'material_detail_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({
    super.key,
    required this.repository,
  });

  final MaterialRepository repository;

  @override
  State<MaterialListScreen> createState() =>
      _MaterialListScreenState();
}

class _MaterialListScreenState
    extends State<MaterialListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Material> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaterialCreateScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadMaterials();
    }
  }

  Future<void> _openDetailScreen(
    Material material,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaterialDetailScreen(
          materialId: material.id,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadMaterials();
    }
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final materials =
          await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = materials;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
        actions: [
          IconButton(
            tooltip: 'Create Material',
            onPressed: _isLoading ? null : _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadMaterials,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaterials,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _materials.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _materials.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
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
            onPressed: _loadMaterials,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_materials.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No materials found.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildMaterialCard(
          context,
          _materials[index],
        );
      },
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    Material material,
  ) {
    return Card(
      child: InkWell(
        onTap: () => _openDetailScreen(material),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    material.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    material.isActive
                        ? 'Active'
                        : 'Inactive',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Code',
              value: material.materialCode,
            ),
            _InfoRow(
              label: 'Category',
              value: material.category,
            ),
            _InfoRow(
              label: 'Unit',
              value: material.unitOfMeasure,
            ),
            if (material.standardUnitCost != null)
              _InfoRow(
                label: 'Standard cost',
                value: _money(
                  material.standardUnitCost!,
                ),
              ),
            if (material.description != null &&
                material.description!.isNotEmpty)
              _InfoRow(
                label: 'Description',
                value: material.description!,
              ),
          ],
        ),
      ),
    ),
    );
  }

  String _money(double amount) {
    return amount.toStringAsFixed(2);
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
            width: 120,
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




