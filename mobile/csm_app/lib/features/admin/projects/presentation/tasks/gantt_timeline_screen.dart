import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';

class GanttTimelineScreen extends StatefulWidget {
  const GanttTimelineScreen({
    super.key,
    required this.tasks,
    required this.projectName,
  });

  final List<WorkTask> tasks;
  final String projectName;

  @override
  State<GanttTimelineScreen> createState() =>
      _GanttTimelineScreenState();
}

class _GanttTimelineScreenState
    extends State<GanttTimelineScreen> {


  final ScrollController _verticalController =
  ScrollController();
  final ScrollController _horizontalController =
  ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  String _monthName(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[month - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final dayWidth = screenWidth >= 1200
        ? 32.0 // Web
        : screenWidth >= 700
        ? 28.0 // Tablet
        : 22.0; // Phone

    const rowHeight = 52.0;

    final datedTasks = widget.tasks
        .where((e) => e.plannedStartDate != null)
        .toList()
      ..sort((a, b) =>
          a.plannedStartDate!.compareTo(b.plannedStartDate!));

    if (datedTasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.projectName} Gantt'),
        ),
        body: const Center(
          child: Text('No scheduled tasks available.'),
        ),
      );
    }

    final start = datedTasks
        .map((e) => e.plannedStartDate!)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final end = datedTasks
        .map((e) => e.plannedEndDate ?? e.plannedStartDate!)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final totalDays = end.difference(start).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} Gantt'),
      ),
      body: Column(
        children: [
          Container(
            height: 56,
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Container(
                  width: 170,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Task',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(totalDays, (i) {
                        final date = start.add(Duration(days: i));
                        final firstDay = date.day == 1 || i == 0;

                        return Container(
                          width: dayWidth,
                          decoration: BoxDecoration(
                            color: _isToday(date)
                                ? Colors.blue.shade50
                                : Colors.transparent,
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (firstDay)
                                Text(
                                  _monthName(date.month),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const SizedBox(height: 10),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isToday(date)
                                      ? Colors.blue
                                      : Colors.black87,
                                  fontWeight: _isToday(date)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 170,
                  child: ListView.builder(
                    controller: _verticalController,
                    itemCount: datedTasks.length,
                    itemBuilder: (context, index) {
                      final task = datedTasks[index];

                      return SizedBox(
                        height: rowHeight,
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalDays * dayWidth,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: datedTasks.length,
                        itemBuilder: (context, index) {
                          final task = datedTasks[index];

                          final taskStart = task.plannedStartDate!;
                          final taskEnd =
                              task.plannedEndDate ?? taskStart;

                          final offset =
                              taskStart.difference(start).inDays;

                          final duration =
                              taskEnd.difference(taskStart).inDays + 1;

                          return SizedBox(
                            height: rowHeight,
                            child: Stack(
                              children: [
                                Row(
                                  children: List.generate(
                                    totalDays,
                                        (_) => Container(
                                      width: dayWidth,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color:
                                            Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: offset * dayWidth,
                                  top: 10,
                                  child: Container(
                                    width: duration * dayWidth,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                      _statusColor(task.status),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Stack(
                                      children: [
                                        FractionallySizedBox(
                                          widthFactor:
                                          task.progressPercentage /
                                              100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.30),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '${task.progressPercentage.toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(WorkTaskStatus status) {
    switch (status) {
      case WorkTaskStatus.notStarted:
        return Colors.grey;
      case WorkTaskStatus.inProgress:
        return Colors.blue;
      case WorkTaskStatus.onHold:
        return Colors.orange;
      case WorkTaskStatus.completed:
        return Colors.green;
      case WorkTaskStatus.cancelled:
        return Colors.red;
    }
  }
}