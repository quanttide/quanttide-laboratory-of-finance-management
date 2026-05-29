import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';

class BudgetFormPage extends StatefulWidget {
  final Budget? budget;
  final List<Entry> entries;

  const BudgetFormPage({
    super.key,
    this.budget,
    required this.entries,
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

  final _entryDescCtrl = TextEditingController();
  final _entryAmtCtrl = TextEditingController();
  bool _isIncome = false;

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
    _entryDescCtrl.dispose();
    _entryAmtCtrl.dispose();
    super.dispose();
  }

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

  void _addEntry() {
    final raw = double.tryParse(_entryAmtCtrl.text);
    if (raw == null || raw <= 0) return;

    final budget = widget.budget;
    if (budget == null) return;

    final amt = _isIncome ? -raw : raw;

    final entry = Entry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      budgetId: budget.id,
      description: _entryDescCtrl.text,
      amount: amt,
      date: DateTime.now(),
    );

    final allEntries = [...widget.entries, entry];
    _storage.saveEntries(allEntries);

    _entryDescCtrl.clear();
    _entryAmtCtrl.clear();
    setState(() => _isIncome = false);
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
              _buildEntrySection(),
              const SizedBox(height: 16),
              _buildEntryList(),
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

  Widget _buildEntrySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '录入流水',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryDescCtrl,
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
                    controller: _entryAmtCtrl,
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
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('支出')),
                    ButtonSegment(value: true, label: Text('收入')),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (v) => setState(() => _isIncome = v.first),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('录入'),
                  onPressed: _addEntry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList() {
    final entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '流水记录（${entries.length}）',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...entries.reversed.take(50).map((e) {
              return ListTile(
                dense: true,
                title: Text(
                  e.description.isNotEmpty ? e.description : '无说明',
                ),
                trailing: Text(
                  '${e.isExpense ? '-' : '+'}¥${e.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: e.isExpense ? Colors.red : Colors.green,
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
