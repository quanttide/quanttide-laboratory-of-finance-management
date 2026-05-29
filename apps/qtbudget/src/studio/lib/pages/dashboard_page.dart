import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/account_code.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import 'account_codes_page.dart';
import 'budget_form_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = StorageService();
  List<Budget> _budgets = [];
  List<AccountCode> _tags = [];
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _tags = _storage.loadAccountCodes();
      _budgets = _storage.loadBudgets();
      _entries = _storage.loadEntries();
    });
  }

  double _spent(String budgetId) {
    return _entries
        .where((e) => e.budgetId == budgetId && e.isExpense)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double _income(String budgetId) {
    return _entries
        .where((e) => e.budgetId == budgetId && e.isIncome)
        .fold(0.0, (s, e) => s + e.amount.abs());
  }

  double _remaining(Budget b) => b.cap - _spent(b.id) + _income(b.id);

  double _burnRate(String budgetId) {
    final days = DateTime.now().difference(
      _entries.where((e) => e.budgetId == budgetId).fold<DateTime?>(
        null, (earliest, e) {
          if (earliest == null || e.date.isBefore(earliest)) return e.date;
          return earliest;
        },
      ) ?? DateTime.now(),
    ).inDays;
    if (days <= 0) return 0;
    return _spent(budgetId) / days;
  }

  void _deleteBudget(Budget budget) {
    _budgets.removeWhere((b) => b.id == budget.id);
    _entries.removeWhere((e) => e.budgetId == budget.id);
    _storage.saveBudgets(_budgets);
    _storage.saveEntries(_entries);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮预算管家'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_outlined),
            tooltip: '标签管理',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountCodesPage()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建预算',
            onPressed: () => _openBudgetForm(),
          ),
        ],
      ),
      body: _budgets.isEmpty
          ? const Center(child: Text('暂无预算，点击右上角 + 创建'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _budgets.length,
              itemBuilder: (_, i) => _buildBudgetCard(_budgets[i]),
            ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _spent(budget.id);
    final income = _income(budget.id);
    final remaining = _remaining(budget);
    final usage = budget.cap > 0 ? spent / budget.cap : 0.0;
    final rate = _burnRate(budget.id);
    final daysLeft = rate > 0 ? (remaining / rate).round() : null;

    final color = remaining < 0
        ? Colors.red
        : usage > 0.8
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(budget.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: usage.clamp(0, 1), color: color),
            const SizedBox(height: 4),
            Text(
              '总额 ¥${_fmt(budget.cap)} · 已花 ¥${_fmt(spent)} · 余额 ¥${_fmt(remaining)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (rate > 0)
              Text(
                '日均消耗 ¥${_fmt(rate)} · 预计可花 ${daysLeft} 天',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            if (income > 0)
              Text(
                '已回款 ¥${_fmt(income)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[700],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteBudget(budget),
        ),
        onTap: () => _openBudgetForm(budget: budget),
      ),
    );
  }

  void _openBudgetForm({Budget? budget}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetFormPage(
          budget: budget,
          tags: _tags,
          entries: _entries.where((e) => e.budgetId == budget?.id).toList(),
        ),
      ),
    );
    _load();
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
