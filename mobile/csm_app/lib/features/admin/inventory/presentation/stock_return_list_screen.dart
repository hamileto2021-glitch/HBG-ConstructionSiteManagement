import 'package:flutter/material.dart';

import '../data/models/stock_return.dart';
import '../data/repositories/stock_movement_repository.dart';
import '../data/repositories/stock_return_repository.dart';
import 'stock_return_create_screen.dart';
import 'stock_return_history_screen.dart';
import 'stock_return_detail_screen.dart';


class StockReturnListScreen extends StatefulWidget {
  const StockReturnListScreen({
    super.key,
    required this.repository,
  });

  final StockReturnRepository repository;

  @override
  State<StockReturnListScreen> createState() =>
      _StockReturnListScreenState();
}

class _StockReturnListScreenState
    extends State<StockReturnListScreen> {
  bool _loading = true;
  List<StockReturn> _returns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _returns = await widget.repository.getAll();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StockReturnCreateScreen(
          repository: StockReturnRepository(),
          stockMovementRepository:
          StockMovementRepository(),
        ),
      ),
    );

    if (created == true) {
      _load();
    }
  }

  String _date(DateTime value) {
    final d = value.toLocal();

    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Returns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StockReturnHistoryScreen(
                        repository:
                        StockMovementRepository(),
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _returns.isEmpty
          ? const Center(
        child: Text(
          'No stock returns found',
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _returns.length,
        itemBuilder: (_, index) {
          final item = _returns[index];

          return Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockReturnDetailScreen(
                      stockReturn: item,
                    ),
                  ),
                );
              },
              leading: const CircleAvatar(
                child: Icon(
                  Icons.keyboard_return,
                ),
              ),
              title: Text(
                item.referenceNumber,
              ),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.materialCode} • ${item.materialName}',
                  ),
                  Text(item.siteName),
                  Text(_date(item.returnDateUtc)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    '${item.returnedQuantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(item.unitOfMeasure),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}