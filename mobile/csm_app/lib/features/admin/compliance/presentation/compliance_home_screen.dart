import 'package:csm_app/core/network/api_client.dart';
import 'package:flutter/material.dart';

import '../data/repositories/document_repository.dart';
import '../safety/data/safety_incident_repository.dart';
import '../safety/presentation/safety_incident_list_screen.dart';
import 'document_list_screen.dart';
import '../permits/data/work_permit_repository.dart';
import '../permits/presentation/work_permit_list_screen.dart';
import '../inspections/data/inspection_repository.dart';
import '../inspections/presentation/inspection_list_screen.dart';
import '../safety_observations/presentation/safety_observation_list_screen.dart';
import '../non_conformance_reports/presentation/non_conformance_report_list_screen.dart';
import '../quality_checklists/presentation/quality_checklist_list_screen.dart';
import '../../compliance/dashboard/presentation/compliance_dashboard_screen.dart';
import '../../compliance/violations/presentation/violation_list_screen.dart';
import '../../compliance/alerts/presentation/compliance_alert_screen.dart';
import '../../compliance/reports/presentation/compliance_reports_screen.dart';

class ComplianceHomeScreen extends StatelessWidget {
  const ComplianceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Compliance & Safety',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Manage safety incidents, permits, inspections and compliance documents.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        _ModuleCard(
          title: 'Compliance Dashboard',
          subtitle: 'Live compliance KPIs & safety overview',
          icon: Icons.dashboard_outlined,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComplianceDashboardScreen(),
              ),
            );
          },
        ),
        _ModuleCard(
          title: 'Violations Register',
          subtitle: 'Open non-compliance & corrective actions',
          icon: Icons.gpp_bad_outlined,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViolationListScreen(),
              ),
            );
          },
        ),
        _ModuleCard(
          title: 'Expiry Alerts',
          subtitle: 'Permits approaching expiry',
          icon: Icons.notifications_active_outlined,
          color: Colors.deepOrange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComplianceAlertScreen(),
              ),
            );
          },
        ),
        _ModuleCard(
          title: 'Audit Reports',
          subtitle: 'Compliance summary & management reports',
          icon: Icons.assessment_outlined,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComplianceReportsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),
        _ModuleCard(
          title: 'Safety Incidents',
          subtitle: 'Accidents & near-miss reporting',
          icon: Icons.health_and_safety_outlined,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SafetyIncidentListScreen(
                  repository: SafetyIncidentRepository(apiClient),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        _ModuleCard(
          title: 'Safety Observations',
          subtitle: 'Near misses & positive observations',
          icon: Icons.visibility_outlined,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SafetyObservationListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        _ModuleCard(
          title: 'Non-Conformance Reports',
          subtitle: 'Quality defects & corrective actions',
          icon: Icons.rule_folder_outlined,
          color: Colors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NonConformanceReportListScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        const SizedBox(height: 12),

        _ModuleCard(
          title: 'Quality Checklists',
          subtitle: 'Reusable QA/QC inspection templates',
          icon: Icons.checklist_rtl_outlined,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QualityChecklistListScreen(),
              ),
            );
          },
        ),

        _ModuleCard(
          title: 'Work Permits',
          subtitle: 'Issue & manage work permits',
          icon: Icons.assignment_turned_in_outlined,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkPermitListScreen(
                  repository: WorkPermitRepository(),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        _ModuleCard(
          title: 'Site Inspections',
          subtitle: 'Safety, quality & compliance inspections',
          icon: Icons.fact_check_outlined,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InspectionListScreen(
                  repository: InspectionRepository(),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        _ModuleCard(
          title: 'Documents',
          subtitle: 'Policies, drawings & certificates',
          icon: Icons.folder_outlined,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentListScreen(
                  repository: DocumentRepository(),
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}