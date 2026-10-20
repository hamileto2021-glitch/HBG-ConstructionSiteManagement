import 'package:flutter/material.dart';

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 14 : 18),
          child: Column(
            children: [
              CircleAvatar(
                radius: isPhone ? 22 : 26,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: color,
                  size: isPhone ? 24 : 28,
                ),
              ),

              const Spacer(),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isPhone ? 30 : 36,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isPhone ? 14 : 15,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}