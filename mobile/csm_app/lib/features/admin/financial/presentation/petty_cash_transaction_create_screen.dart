import 'package:flutter/material.dart';

import '../data/models/petty_cash_account.dart';
import '../data/models/petty_cash_transaction.dart';
import '../data/repositories/petty_cash_transaction_repository.dart';

class PettyCashTransactionCreateScreen extends StatefulWidget {
  const PettyCashTransactionCreateScreen({
    super.key,
    required this.account,
  });

  final PettyCashAccount account;

  @override
  State<PettyCashTransactionCreateScreen> createState() =>
      _PettyCashTransactionCreateScreenState();
}

class _PettyCashTransactionCreateScreenState
    extends State<PettyCashTransactionCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _repository = PettyCashTransactionRepository();

  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _saving = false;

  PettyCashTransactionType _type =
      PettyCashTransactionType.cashOut;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _repository.create(
        pettyCashAccountId: widget.account.id,
        transactionType:
        _type == PettyCashTransactionType.cashIn
            ? 'CashIn'
            : 'CashOut',
        referenceNumber: _referenceController.text.trim(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = _type == PettyCashTransactionType.cashIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Cash Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.green.shade700,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ETB ${widget.account.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.account.accountName,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<PettyCashTransactionType>(
              segments: const [
                ButtonSegment(
                  value:
                  PettyCashTransactionType.cashIn,
                  icon: Icon(Icons.arrow_downward),
                  label: Text('Cash In'),
                ),
                ButtonSegment(
                  value:
                  PettyCashTransactionType.cashOut,
                  icon: Icon(Icons.arrow_upward),
                  label: Text('Cash Out'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() => _type = value.first);
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (ETB)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(v) == null) {
                  return 'Invalid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: Icon(
                isCashIn
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : isCashIn
                    ? 'Receive Cash'
                    : 'Spend Cash',
              ),
            ),
          ],
        ),
      ),
    );
  }
}