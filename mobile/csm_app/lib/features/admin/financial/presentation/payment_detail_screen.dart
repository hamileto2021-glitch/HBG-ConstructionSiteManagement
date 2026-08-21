import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/payment_repository.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
    required this.repository,
  });

  final String paymentId;
  final PaymentRepository repository;

  @override
  State<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState
    extends State<PaymentDetailScreen> {
  Payment? _payment;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payment =
      await widget.repository.getById(widget.paymentId);

      if (!mounted) return;

      setState(() {
        _payment = payment;
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

  Future<void> _changeStatus(
      PaymentStatus status,
      ) async {
    if (_payment == null) return;

    setState(() => _updating = true);

    try {
      final updated =
      await widget.repository.changeStatus(
        paymentId: _payment!.id,
        status: status,
      );

      if (!mounted) return;

      setState(() => _payment = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status changed to ${status.displayName}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    final payment = _payment!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(payment.paymentNumber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    payment.direction ==
                        PaymentDirection.incoming
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 48,
                    color:
                    payment.direction ==
                        PaymentDirection.incoming
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    payment.paymentNumber,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      payment.status.displayName,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _SectionTitle('Payment Information'),
          _InfoRow(
            'Direction',
            payment.direction.displayName,
          ),
          _InfoRow(
            'Date',
            payment.paymentDate
                .toIso8601String()
                .split('T')
                .first,
          ),
          _InfoRow(
            'Currency',
            payment.currencyCode,
          ),
          _InfoRow(
            'Method',
            payment.paymentMethod ?? '—',
          ),
          _InfoRow(
            'Reference',
            payment.referenceNumber ?? '—',
          ),

          const SizedBox(height: 16),

          _SectionTitle('Amount'),
          _InfoRow(
            'Amount',
            payment.amount.toStringAsFixed(2),
          ),

          const SizedBox(height: 16),

          _SectionTitle('Notes'),
          Text(payment.notes ?? 'No notes'),

          const SizedBox(height: 24),

          if (_updating)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            ..._statusButtons(payment),
        ],
      ),
    );
  }

  List<Widget> _statusButtons(Payment payment) {
    switch (payment.status) {
      case PaymentStatus.pending:
        return [
          FilledButton(
            onPressed: () => _changeStatus(
              PaymentStatus.completed,
            ),
            child: const Text('Complete Payment'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _changeStatus(
              PaymentStatus.cancelled,
            ),
            child: const Text('Cancel Payment'),
          ),
        ];

      case PaymentStatus.completed:
      case PaymentStatus.cancelled:
        return const [
          Center(
            child: Text(
              'No actions available.',
            ),
          ),
        ];
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      this.label,
      this.value,
      );

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}