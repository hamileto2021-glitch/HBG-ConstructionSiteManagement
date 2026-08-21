import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/invoice_repository.dart';

import '../../procurement/data/repositories/vendor_repository.dart';
import 'payment_create_screen.dart';
import 'payment_detail_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({
    super.key,
    required this.repository,
  });

  final PaymentRepository repository;

  @override
  State<PaymentListScreen> createState() =>
      _PaymentListScreenState();
}

class _PaymentListScreenState
    extends State<PaymentListScreen> {
  List<Payment> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  double get _totalIncoming => _payments
      .where(
        (e) => e.direction == PaymentDirection.incoming,
  )
      .fold(0, (a, b) => a + b.amount);

  double get _totalOutgoing => _payments
      .where(
        (e) => e.direction == PaymentDirection.outgoing,
  )
      .fold(0, (a, b) => a + b.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadPayments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PaymentCreateScreen(
                repository: widget.repository,
                invoiceRepository: InvoiceRepository(),
                vendorRepository: VendorRepository(),
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadPayments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
      body: _buildBody(),
      bottomNavigationBar:
      _loading || _payments.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.all(16),
        color:
        Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text('Incoming'),
                Text(
                  _totalIncoming.toStringAsFixed(2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text('Outgoing'),
                Text(
                  _totalOutgoing.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPayments,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.payments_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text('No payments found.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          return _PaymentCard(
            payment: _payments[index],
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentDetailScreen(
                    paymentId: _payments[index].id,
                    repository: widget.repository,
                  ),
                ),
              );

              if (mounted) {
                await _loadPayments();
              }
            },
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onTap,
  });

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                  payment.direction ==
                      PaymentDirection.incoming
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    payment.direction ==
                        PaymentDirection.incoming
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color:
                    payment.direction ==
                        PaymentDirection.incoming
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.paymentNumber,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        payment.direction.displayName,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    payment.status.displayName,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount'),
                Text(
                  '${payment.amount.toStringAsFixed(2)} ${payment.currencyCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date'),
                Text(
                  payment.paymentDate
                      .toIso8601String()
                      .split('T')
                      .first,
                ),
              ],
            ),
          ],
        ),
          ),
        ),
    );
  }
}