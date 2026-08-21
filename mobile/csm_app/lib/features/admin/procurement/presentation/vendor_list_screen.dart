import 'package:flutter/material.dart';

import '../data/models/vendor.dart';
import '../data/repositories/vendor_repository.dart';
import 'vendor_create_screen.dart';
import 'vendor_detail_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({
    super.key,
    required this.repository,
  });

  final VendorRepository repository;

  @override
  State<VendorListScreen> createState() =>
      _VendorListScreenState();
}

class _VendorListScreenState
    extends State<VendorListScreen> {
  final List<Vendor> _vendors = [];

  bool _isLoading = true;
  bool? _activeFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vendors = await widget.repository.getAll(
        isActive: _activeFilter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _vendors
          ..clear()
          ..addAll(vendors);
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

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorCreateScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadVendors();
    }
  }

  Future<void> _openDetailScreen(Vendor vendor) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorDetailScreen(
          vendorId: vendor.id,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          PopupMenuButton<bool?>(
            tooltip: 'Filter',
            initialValue: _activeFilter,
            onSelected: (value) {
              setState(() {
                _activeFilter = value;
              });
              _loadVendors();
            },
            itemBuilder: (_) => const [
              PopupMenuItem<bool?>(
                value: null,
                child: Text('All'),
              ),
              PopupMenuItem<bool?>(
                value: true,
                child: Text('Active'),
              ),
              PopupMenuItem<bool?>(
                value: false,
                child: Text('Inactive'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Add Vendor',
            onPressed:
                _isLoading ? null : _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadVendors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVendors,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _vendors.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _vendors.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          Center(
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
                    onPressed: _loadVendors,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_vendors.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text('No vendors found.'),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vendors.length,
      itemBuilder: (context, index) {
        final vendor = _vendors[index];

        return _VendorCard(
          vendor: vendor,
          onTap: () => _openDetailScreen(vendor),
        );
      },
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.onTap,
  });

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vendor.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(
                      vendor.isActive
                          ? 'Active'
                          : 'Inactive',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Vendor',
                value: vendor.vendorCode,
              ),
              if (vendor.contactPerson != null &&
                  vendor.contactPerson!.isNotEmpty)
                _InfoRow(
                  label: 'Contact',
                  value: vendor.contactPerson!,
                ),
              if (vendor.phoneNumber != null &&
                  vendor.phoneNumber!.isNotEmpty)
                _InfoRow(
                  label: 'Phone',
                  value: vendor.phoneNumber!,
                ),
              if (vendor.email != null &&
                  vendor.email!.isNotEmpty)
                _InfoRow(
                  label: 'Email',
                  value: vendor.email!,
                ),
            ],
          ),
        ),
      ),
    );
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
            width: 100,
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
