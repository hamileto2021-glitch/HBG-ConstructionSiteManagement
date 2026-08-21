import 'package:flutter/material.dart';

import '../data/repositories/material_repository.dart';
import '../data/repositories/vendor_repository.dart';
import '../data/repositories/purchase_order_repository.dart';
import '../data/repositories/material_request_repository.dart';
import 'material_list_screen.dart';
import 'vendor_list_screen.dart';
import 'purchase_order_list_screen.dart';
import 'material_request_list_screen.dart';

import '../data/repositories/goods_receipt_repository.dart';
import 'goods_receipt_list_screen.dart';

import '../equipment_downtime/data/repositories/equipment_downtime_repository.dart';
import 'equipment_downtime_page.dart';
import '../data/repositories/equipment_repository.dart';
import 'equipment_list_screen.dart';
import 'equipment_assignment_list_screen.dart';
import 'equipment_maintenance_list_screen.dart';


class ProcurementDashboardScreen extends StatelessWidget {
  const ProcurementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Procurement', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Manage materials and vendors.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _ModuleCard(
          icon: Icons.inventory_2_outlined,
          title: 'Materials',
          description:
              'Manage construction materials, costs, categories, and active status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MaterialListScreen(repository: MaterialRepository()),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.business_outlined,
          title: 'Vendors',
          description:
              'Manage suppliers, contact information, banking details, and status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    VendorListScreen(repository: VendorRepository()),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.construction_outlined,
          title: 'Equipment',
          description:
          'Manage construction equipment, ownership, status, meters, and rental information.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EquipmentListScreen(
                  repository: EquipmentRepository(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.request_quote_outlined,
          title: 'Material Requests',
          description:
              'Create, submit, approve, reject, and track material requests.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MaterialRequestListScreen(
                  repository: MaterialRequestRepository(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.receipt_long_outlined,
          title: 'Purchase Orders',
          description: 'Create, review, approve, and manage purchase orders.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PurchaseOrderListScreen(
                  repository: PurchaseOrderRepository(),
                ),
              ),
            );
          },
        ),
        _ModuleCard(
          icon: Icons.inventory_2_outlined,
          title: 'Goods Receipts',
          description:
          'Record and review goods received against purchase orders.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GoodsReceiptListScreen(
                  repository: GoodsReceiptRepository(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.build_circle_outlined,
          title: 'Equipment Downtime',
          description:
          'Track equipment breakdowns, downtime duration, causes, resolutions, and return-to-service status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EquipmentDowntimeScreen(
                  repository: EquipmentDowntimeRepository(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Equipment Assignments',
          description:
          'Assign equipment to construction sites and track active and released assignments.',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EquipmentAssignmentListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ModuleCard(
          icon: Icons.build_outlined,
          title: 'Equipment Maintenance',
          description:
          'Schedule, record, and track equipment maintenance, service history, costs, and next maintenance dates.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    EquipmentMaintenanceListScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
