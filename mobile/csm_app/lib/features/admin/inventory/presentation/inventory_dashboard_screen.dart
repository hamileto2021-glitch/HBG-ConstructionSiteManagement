import 'package:flutter/material.dart';

import 'stock_movement_list_screen.dart';
import 'stock_return_history_screen.dart';
import '../data/repositories/stock_movement_repository.dart';
import '../../procurement/data/repositories/material_repository.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/repositories/stock_issue_repository.dart';
import 'stock_issue_create_screen.dart';
import '../data/repositories/stock_return_repository.dart';
import 'stock_return_create_screen.dart';
import '../data/repositories/stock_transfer_repository.dart';
import 'stock_transfer_create_screen.dart';
import '../data/repositories/stock_adjustment_repository.dart';
import 'stock_adjustment_create_screen.dart';
import '../data/repositories/daily_material_usage_repository.dart';
import 'daily_material_usage_create_screen.dart';
import '../../projects/data/repositories/daily_progress_log_repository.dart';
import '../data/repositories/stock_balance_repository.dart';
import 'stock_balance_site_list_screen.dart';
import '../../projects/data/repositories/project_repository.dart';

class InventoryDashboardScreen extends StatelessWidget {
  const InventoryDashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Inventory & Stock',
          style: Theme.of(context)
              .textTheme
              .headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Manage stock movements, issues, returns, transfers, and adjustments.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge,
        ),
        const SizedBox(height: 24),
        _ModuleCard(
          icon: Icons.inventory_2_outlined,
          title: 'Stock Balance',
          description:
          'View current stock balance by site and material, including on-hand, reserved, and available quantities.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockBalanceSiteListScreen(
                  repository: StockBalanceRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.swap_horiz_outlined,
          title: 'Stock Movements',
          description:
              'Review stock movement history and transaction details.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockMovementListScreen(
                  repository: StockMovementRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.outbox_outlined,
          title: 'Stock Issues',
          description:
              'Issue materials from stock to construction sites or projects.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockIssueCreateScreen(
                  repository: StockIssueRepository(),
                  materialRepository: MaterialRepository(),
                  siteRepository: SiteRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.fact_check_outlined,
          title: 'Daily Material Usage',
          description:
              'Record daily material usage, returns, variance, and supervisor review.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DailyMaterialUsageCreateScreen(
                  repository: DailyMaterialUsageRepository(),
                  materialRepository: MaterialRepository(),
                  siteRepository: SiteRepository(),
                  projectRepository: ProjectRepository(),
                  dailyProgressLogRepository:
                      DailyProgressLogRepository(),
                ),
              ),
            );
          },
        ),


        _ModuleCard(
          icon: Icons.history_outlined,
          title: 'Material Return Audit Trail',
          description:
              'Review returned materials, references, quantities, and return audit details.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockReturnHistoryScreen(
                  repository: StockMovementRepository(),
                ),
              ),
            );
          },
        ),
        _ModuleCard(
          icon: Icons.keyboard_return_outlined,
          title: 'Stock Returns',
          description:
              'Record materials returned back into stock.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockReturnCreateScreen(
                  repository: StockReturnRepository(),
                  stockMovementRepository:
                      StockMovementRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.compare_arrows_outlined,
          title: 'Stock Transfers',
          description:
              'Transfer materials between stock locations or sites.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockTransferCreateScreen(
                  repository: StockTransferRepository(),
                  materialRepository: MaterialRepository(),
                  siteRepository: SiteRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.tune_outlined,
          title: 'Stock Adjustments',
          description:
              'Correct stock quantities and record adjustment reasons.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockAdjustmentCreateScreen(
                  repository: StockAdjustmentRepository(),
                  materialRepository: MaterialRepository(),
                  siteRepository: SiteRepository(),
                ),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

