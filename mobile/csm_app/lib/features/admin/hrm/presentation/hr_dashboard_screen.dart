import 'package:flutter/material.dart';

import '../data/repositories/attendance_repository.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/leave_repository.dart';
import '../data/repositories/payroll_repository.dart';
import '../data/repositories/site_assignment_repository.dart';
import 'attendance_list_screen.dart';
import 'employee_list_screen.dart';
import 'leave_list_screen.dart';
import 'payroll_list_screen.dart';
import 'site_assignment_list_screen.dart';
import 'timesheet_list_screen.dart';
import '../data/repositories/timesheet_repository.dart';

class HrDashboardScreen extends StatelessWidget {
  const HrDashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Human Resources'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'HR Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage employees, attendance, leave, payroll, and site assignments.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildModuleCard(
            context,
            icon: Icons.badge_outlined,
            title: 'Employees',
            description:
                'Create, view, edit, and manage employee status.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeListScreen(
                    repository: EmployeeRepository(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            context,
            icon: Icons.event_note_outlined,
            title: 'Leave Management',
            description:
                'Manage employee leave requests and leave status.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaveListScreen(
                    repository: LeaveRepository(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            context,
            icon: Icons.fact_check_outlined,
            title: 'Attendance',
            description:
                'View attendance records and attendance details.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceListScreen(
                    repository: AttendanceRepository(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            context,
            icon: Icons.assignment_ind_outlined,
            title: 'Site Assignments',
            description:
                'Assign employees to construction sites and manage assignment periods.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SiteAssignmentListScreen(
                    repository: SiteAssignmentRepository(),
                  ),
                ),
              );
            },
          ),          _buildModuleCard(
            context,
            icon: Icons.access_time_outlined,
            title: 'Timesheets',
            description:
                'Manage employee timesheets, submissions, and approvals.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TimesheetListScreen(
                    repository: TimesheetRepository(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            context,
            icon: Icons.payments_outlined,
            title: 'Payroll Management',
            description:
                'Create, calculate, approve, and manage employee payroll.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PayrollListScreen(
                    repository: PayrollRepository(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 42,
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
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

