import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/account_code.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import 'budget_form_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = StorageService();
  List<Budget> _budgets = [];
  List<AccountCode> _codes = [];
  List<Transaction> _txns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _codes = _storage.loadAccountCodes();
      _budgets = _storage.loadBudgets();
      _txns = _storage.loadTransactions();
    });
  }

  void _deleteBudget(Budget budget) {
    _budgets.removeWhere((b) => b.id == budget.id);
    _txns.removeWhere((t) => t.budgetId == budget.id);
    _storage.saveBudgets(_budgets);
    _storage.saveTransactions(_txns);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮预算管家'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
    final rate = budget.executionRate;
    final color = rate > 1
        ? Colors.red
        : rate > 0.8
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(budget.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${budget.year}${budget.month != null ? '/${budget.month}' : ''} · ${budget.status.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: rate.clamp(0, 1), color: color),
            const SizedBox(height: 2),
            Text(
              '预算 ¥${_fmt(budget.totalPlanned)} · 已用 ¥${_fmt(budget.totalActual)} · ${(rate * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
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
          codes: _codes,
          txns: _txns.where((t) => t.budgetId == budget?.id).toList(),
        ),
      ),
    );
    _load();
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
