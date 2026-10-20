import 'package:flutter/material.dart';

class AdaptiveColumn {
  const AdaptiveColumn({
    required this.label,
    this.value,
    this.cell,
    this.numeric = false,
  });

  final String label;

  // Text value (existing behavior)
  final String Function(Map<String, dynamic>)? value;

  // Custom widget (new)
  final Widget Function(Map<String, dynamic>)? cell;

  final bool numeric;
}

class AdaptiveDataTable extends StatefulWidget {
  const AdaptiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.emptyMessage = 'No records found',
  });

  final List<AdaptiveColumn> columns;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic>)? onRowTap;
  final String emptyMessage;

  @override
  State<AdaptiveDataTable> createState() => _AdaptiveDataTableState();
}

class _AdaptiveDataTableState extends State<AdaptiveDataTable> {
  int? _sortColumn;
  bool _ascending = true;
  String _search = '';
  int _page = 0;
  static const int _pageSize = 10;

  List<Map<String, dynamic>> get _rows {
    var data = widget.rows.where((row) {
      if (_search.isEmpty) return true;

      final text = row.values
          .join(' ')
          .toLowerCase();

      return text.contains(_search.toLowerCase());
    }).toList();

    if (_sortColumn != null) {
      final column = widget.columns[_sortColumn!];

// Custom widget columns are not sortable
      if (column.value != null) {
        data.sort((a, b) {
          final av = column.value!(a);
          final bv = column.value!(b);

          return _ascending
              ? av.compareTo(bv)
              : bv.compareTo(av);
        });
      }
    }

    return data;
  }

  List<Map<String, dynamic>> get _pagedRows {
    final start = _page * _pageSize;
    final end = (_rows.length < start + _pageSize)
        ? _rows.length
        : start + _pageSize;

    return _rows.sublist(start, end);
  }

  bool get _desktop =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(widget.emptyMessage)),
        ),
      );
    }

    return _desktop
        ? _desktopTable()
        : _mobileCards();
  }

  Widget _desktopTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _page = 0; // Reset to first page when searching
                });
              },
            ),
          ),

          const Divider(height: 1),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumn,
              sortAscending: _ascending,
              columns: List.generate(widget.columns.length, (i) {
                final c = widget.columns[i];

                return DataColumn(
                  label: Text(
                    c.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: c.numeric,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumn = index;
                      _ascending = ascending;
                    });
                  },
                );
              }),
              rows: _pagedRows.map((row) {
                return DataRow(
                  onSelectChanged: (_) => widget.onRowTap?.call(row),
                  cells: widget.columns.map((c) {
                    if (c.cell != null) {
                      return DataCell(c.cell!(row));
                    }

                    return DataCell(Text(c.value!(row)));
                  }).toList(),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  '${_rows.isEmpty ? 0 : _page * _pageSize + 1}'
                      '–${(_page * _pageSize) + _pagedRows.length} of ${_rows.length}',
                ),
                const Spacer(),
                IconButton(
                  onPressed: _page == 0
                      ? null
                      : () => setState(() => _page--),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: (_page + 1) * _pageSize >= _rows.length
                      ? null
                      : () => setState(() => _page++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileCards() {
    return Column(
      children: _rows.map((row) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onRowTap == null
                ? null
                : () => widget.onRowTap!(row),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.columns.map((c) {
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: c.cell != null
                                ? c.cell!(row)
                                : Text(
                              c.value!(row),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}