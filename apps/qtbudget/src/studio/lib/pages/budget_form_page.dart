import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/account_code.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import 'account_codes_page.dart';

class BudgetFormPage extends StatefulWidget {
  final Budget? budget;
  final List<AccountCode> tags;
  final List<Transaction> txns;

  const BudgetFormPage({
    super.key,
    this.budget,
    required this.tags,
    required this.txns,
  });

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _storage = StorageService();

  late TextEditingController _nameCtrl;
  late TextEditingController _capCtrl;
  late TextEditingController _noteCtrl;
  late final _editing = widget.budget != null;

  final _txnDescCtrl = TextEditingController();
  final _txnAmtCtrl = TextEditingController();
  String? _txnTagId;
  TransactionType _txnType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _capCtrl = TextEditingController(
      text: b != null ? b.cap.toStringAsFixed(0) : '',
    );
    _noteCtrl = TextEditingController(text: b?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    _noteCtrl.dispose();
    _txnDescCtrl.dispose();
    _txnAmtCtrl.dispose();
    super.dispose();
  }

  List<AccountCode> get _tags => _storage.loadAccountCodes();

  void _save() {
    final cap = double.tryParse(_capCtrl.text);
    if (cap == null || cap <= 0) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final budgets = _storage.loadBudgets();

    if (_editing) {
      final b = widget.budget!;
      b.name = name;
      b.cap = cap;
      b.note = _noteCtrl.text.trim();
      final idx = budgets.indexWhere((x) => x.id == b.id);
      if (idx >= 0) budgets[idx] = b;
    } else {
      budgets.add(
        Budget(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          cap: cap,
          note: _noteCtrl.text.trim(),
        ),
      );
    }

    _storage.saveBudgets(budgets);
    if (mounted) Navigator.pop(context);
  }

  void _addTransaction() {
    final amt = double.tryParse(_txnAmtCtrl.text);
    if (amt == null || amt <= 0) return;

    final budget = widget.budget;
    if (budget == null) return;

    final txn = Transaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      budgetId: budget.id,
      description: _txnDescCtrl.text,
      amount: amt,
      date: DateTime.now(),
      type: _txnType,
      tagId: _txnTagId,
    );

    final allTxns = [...widget.txns, txn];
    _storage.saveTransactions(allTxns);

    _txnDescCtrl.clear();
    _txnAmtCtrl.clear();
    setState(() {
      _txnTagId = null;
      _txnType = TransactionType.expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? '编辑预算' : '新建预算'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetInfo(),
            if (_editing) ...[
              const SizedBox(height: 16),
              _buildTransactionSection(),
              const SizedBox(height: 16),
              _buildTransactionList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '预算名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '总额',
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: '备注（可选）'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '录入收支',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _txnDescCtrl,
                    decoration: const InputDecoration(
                      labelText: '说明',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _txnAmtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '金额',
                      isDense: true,
                      prefixText: '¥ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _txnTagId,
              decoration: const InputDecoration(
                labelText: '标签（可选）',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('无标签')),
                ..._tags.map(
                  (t) => DropdownMenuItem(value: t.id, child: Text('${t.code} ${t.name}')),
                ),
              ],
              onChanged: (v) => setState(() => _txnTagId = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('支出'),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('收入'),
                    ),
                  ],
                  selected: {_txnType},
                  onSelectionChanged: (v) => setState(() => _txnType = v.first),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('管理标签'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountCodesPage()),
                    );
                    setState(() {});
                  },
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('录入'),
                  onPressed: _addTransaction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final txns = widget.txns;
    if (txns.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收支记录（${txns.length}）',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...txns.reversed.take(50).map((t) {
              final tag = t.tagId != null
                  ? _tags.where((c) => c.id == t.tagId).firstOrNull
                  : null;
              return ListTile(
                dense: true,
                title: Text(
                  t.description.isNotEmpty ? t.description : (tag?.name ?? ''),
                ),
                subtitle: tag != null
                    ? Text('${tag.code} ${tag.name}',
                        style: Theme.of(context).textTheme.bodySmall)
                    : null,
                trailing: Text(
                  '${t.type == TransactionType.expense ? '-' : '+'}¥${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: t.type == TransactionType.expense
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
