import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/account_code.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class BudgetFormPage extends StatefulWidget {
  final Budget? budget;
  final List<AccountCode> codes;
  final List<Transaction> txns;

  const BudgetFormPage({
    super.key,
    this.budget,
    required this.codes,
    required this.txns,
  });

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final _storage = StorageService();
  late final _editing = widget.budget != null;

  late TextEditingController _nameCtrl;
  late int _year;
  late int? _month;
  late List<BudgetItem> _items;

  final _txnDescCtrl = TextEditingController();
  final _txnAmtCtrl = TextEditingController();
  String _txnCodeId = '';
  TransactionType _txnType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    final now = DateTime.now();
    _year = b?.year ?? now.year;
    _month = b?.month;
    _items = b?.items ?? [];

    final expenseCodes = widget.codes
        .where((c) => c.type == AccountType.expense)
        .toList();
    _txnCodeId = expenseCodes.isNotEmpty ? expenseCodes.first.id : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _txnDescCtrl.dispose();
    _txnAmtCtrl.dispose();
    super.dispose();
  }

  List<AccountCode> get _expenseCodes =>
      widget.codes.where((c) => c.type == AccountType.expense).toList();

  List<AccountCode> get _incomeCodes =>
      widget.codes.where((c) => c.type == AccountType.income).toList();

  void _save() {
    final budgets = _storage.loadBudgets();

    if (_editing) {
      final b = widget.budget!;
      b.name = _nameCtrl.text;
      b.year = _year;
      b.month = _month;
      b.items = _items;
      final idx = budgets.indexWhere((x) => x.id == b.id);
      if (idx >= 0) budgets[idx] = b;
    } else {
      budgets.add(
        Budget(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameCtrl.text,
          year: _year,
          month: _month,
          items: _items,
        ),
      );
    }

    _storage.saveBudgets(budgets);
    if (mounted) Navigator.pop(context);
  }

  void _addTransaction() {
    final amt = double.tryParse(_txnAmtCtrl.text);
    if (amt == null || amt <= 0) return;
    if (_txnCodeId.isEmpty) return;

    final budget = widget.budget;
    if (budget == null) return;

    final txn = Transaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      budgetId: budget.id,
      accountCodeId: _txnCodeId,
      description: _txnDescCtrl.text,
      amount: amt,
      date: DateTime.now(),
      type: _txnType,
    );

    final allTxns = [...widget.txns, txn];
    _storage.saveTransactions(allTxns);

    // 更新预算实际金额
    final item = _items.firstWhere(
      (i) => i.accountCodeId == _txnCodeId,
      orElse: () => BudgetItem(
        accountCodeId: _txnCodeId,
        accountName: widget.codes.firstWhere((c) => c.id == _txnCodeId).name,
      ),
    );
    if (!_items.contains(item)) _items.add(item);
    item.actualAmount += _txnType == TransactionType.expense ? amt : -amt;

    _txnDescCtrl.clear();
    _txnAmtCtrl.clear();
    setState(() {});
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
            const SizedBox(height: 16),
            _buildItemsSection(),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(labelText: '年份'),
                    items: List.generate(5, (i) => DateTime.now().year - 1 + i)
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _month,
                    decoration: const InputDecoration(labelText: '月份（空=年度）'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('年度预算')),
                      ...List.generate(12, (i) => i + 1).map(
                        (m) => DropdownMenuItem(value: m, child: Text('$m 月')),
                      ),
                    ],
                    onChanged: (v) => setState(() => _month = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '预算科目',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加科目'),
                  onPressed: _addItem,
                ),
              ],
            ),
            const Divider(),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(item.accountName)),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: '¥ ',
                        ),
                        controller: TextEditingController(
                          text: item.plannedAmount > 0
                              ? item.plannedAmount.toString()
                              : '',
                        ),
                        onChanged: (v) {
                          item.plannedAmount = double.tryParse(v) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择科目'),
        children: _expenseCodes.map((code) {
          return SimpleDialogOption(
            onPressed: () {
              if (!_items.any((i) => i.accountCodeId == code.id)) {
                _items.add(
                  BudgetItem(accountCodeId: code.id, accountName: code.name),
                );
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text('${code.code} ${code.name}'),
          );
        }).toList(),
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
            DropdownButtonFormField<String>(
              value: _txnCodeId,
              decoration: const InputDecoration(labelText: '科目', isDense: true),
              items: widget.codes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _txnCodeId = v!),
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
              final code = widget.codes
                  .where((c) => c.id == t.accountCodeId)
                  .firstOrNull;
              return ListTile(
                dense: true,
                title: Text(
                  t.description.isNotEmpty ? t.description : (code?.name ?? ''),
                ),
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
