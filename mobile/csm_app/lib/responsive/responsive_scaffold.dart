import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'desktop_sidebar.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.appBarActions = const [],
    this.drawer,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  final List<Widget> appBarActions;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            DesktopSidebar(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search projects, employees, equipment...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        ...appBarActions,

                        const SizedBox(width: 12),

                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.person),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
      ),
      drawer: drawer,
      body: body,
    );
  }
}