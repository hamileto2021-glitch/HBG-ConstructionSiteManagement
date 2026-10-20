import 'package:flutter/material.dart';

import '../../../../../responsive/breakpoints.dart';
import '../../../../../shared/widgets/adaptive_data_table.dart';
import '../../data/models/daily_site_diary.dart';
import '../../data/repositories/daily_site_diary_repository.dart';
import '../photos/daily_progress_photo_screen.dart';
import 'daily_site_diary_create_screen.dart';
import 'daily_site_diary_edit_screen.dart';



class DailySiteDiaryListScreen extends StatefulWidget {
  const DailySiteDiaryListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.constructionSiteId,
  });

  final String projectId;
  final String projectName;
  final String constructionSiteId;

  @override
  State<DailySiteDiaryListScreen> createState() =>
      _DailySiteDiaryListScreenState();
}

class _DailySiteDiaryListScreenState
    extends State<DailySiteDiaryListScreen> {
  final DailySiteDiaryRepository _repository =
  DailySiteDiaryRepository();

  bool _isLoading = true;
  String? _error;
  List<DailySiteDiary> _diaries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repository.getAll(
        projectId: widget.projectId,
        siteId: widget.constructionSiteId,
      );

      if (!mounted) return;

      setState(() {
        _diaries = data
            .where((e) =>
        e.projectId == widget.projectId &&
            e.siteId == widget.constructionSiteId)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailySiteDiaryCreateScreen(
          projectId: widget.projectId,
          constructionSiteId:
          widget.constructionSiteId,
          repository: _repository,
        ),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _openEdit(DailySiteDiary diary) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailySiteDiaryEditScreen(
          diary: diary,
          repository: _repository,
        ),
      ),
    );

    if (updated == true) {
      await _load();
    }
  }

  Future<void> _deleteDiary(DailySiteDiary diary) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Daily Diary'),
        content: Text(
          'Delete diary for ${_date(diary.diaryDate)}?\n\nThis action cannot be undone.',
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
    );

    if (confirm != true) return;

    try {
      await _repository.delete(diary.id);

      if (!mounted) return;

      setState(() {
        _diaries.removeWhere((d) => d.id == diary.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary deleted')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _showDiaryActions(DailySiteDiary diary) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Diary'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Progress Photos'),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Diary'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        await _openEdit(diary);
        break;

      case 'photos':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyProgressPhotoScreen(
              diaryId: diary.id,
            ),
          ),
        );
        break;

      case 'delete':
        await _deleteDiary(diary);
        break;
    }
  }

  int get _todayCount {
    final today = DateTime.now();

    return _diaries.where((d) {
      return d.diaryDate.year == today.year &&
          d.diaryDate.month == today.month &&
          d.diaryDate.day == today.day;
    }).length;
  }

  double get _avgWorkforce {
    if (_diaries.isEmpty) return 0;

    final total = _diaries.fold<int>(
      0,
          (sum, d) => sum + d.workforceCount,
    );

    return total / _diaries.length;
  }

  int get _equipmentTotal => _diaries.fold(
    0,
        (sum, d) => sum + d.equipmentInUse,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text('${widget.projectName} Daily Diary'),
        actions: [
          IconButton(
            tooltip: 'New Diary',
            icon: const Icon(Icons.add),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!),
              ),
            ),
          ),
        ],
      );
    }

    if (_diaries.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: Text('No Daily Site Diaries'),
          ),
        ],
      );
    }

    if (AppBreakpoints.isDesktop(context)) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _DiaryKpiCard(
                  title: 'Diaries',
                  value: '${_diaries.length}',
                  icon: Icons.book,
                  color: Colors.blue,
                ),
                _DiaryKpiCard(
                  title: 'Today',
                  value: '$_todayCount',
                  icon: Icons.today,
                  color: Colors.green,
                ),
                _DiaryKpiCard(
                  title: 'Avg Workforce',
                  value:
                  _avgWorkforce.toStringAsFixed(0),
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                _DiaryKpiCard(
                  title: 'Equipment',
                  value: '$_equipmentTotal',
                  icon: Icons.construction,
                  color: Colors.deepPurple,
                ),
              ],
            ),

            const SizedBox(height: 16),

            AdaptiveDataTable(
              columns: [
                AdaptiveColumn(
                  label: 'Date',
                  value: (r) => r['date'],
                ),
                AdaptiveColumn(
                  label: 'Weather',
                  value: (r) => r['weather'],
                ),
                AdaptiveColumn(
                  label: 'Temp',
                  value: (r) => r['temp'],
                  numeric: true,
                ),
                AdaptiveColumn(
                  label: 'Workforce',
                  value: (r) => r['workers'],
                  numeric: true,
                ),
                AdaptiveColumn(
                  label: 'Equipment',
                  value: (r) => r['equipment'],
                  numeric: true,
                ),

              ],
              rows: _diaries.map((d) => {
                'item': d,
                'date': _date(d.diaryDate),
                'weather': d.weather.name,
                'temp': '${d.temperature.toStringAsFixed(1)}°',
                'workers': d.workforceCount.toString(),
                'equipment': d.equipmentInUse.toString(),
              }).toList(),
              onRowTap: (row) {
                final diary = row['item'] as DailySiteDiary;
                _showDiaryActions(diary);
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _diaries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final diary = _diaries[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _date(diary.diaryDate),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ),
                    Chip(
                      label: Text(
                        diary.weather.name
                            .toUpperCase(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    'Temperature: ${diary.temperature}°C'),
                Text(
                    'Workforce: ${diary.workforceCount}'),
                Text(
                    'Equipment: ${diary.equipmentInUse}'),
                const Divider(height: 24),
                Text(
                  diary.workPerformed,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () => _openEdit(diary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Photos'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyProgressPhotoScreen(
                                diaryId: diary.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDiary(diary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _DiaryKpiCard extends StatelessWidget {
  const _DiaryKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor:
              color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}