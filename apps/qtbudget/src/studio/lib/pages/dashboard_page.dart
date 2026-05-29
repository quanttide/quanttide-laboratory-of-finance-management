import 'package:flutter/material.dart';
import '../models/journal.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import 'journal_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = StorageService();
  List<Journal> _journals = [];
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _journals = _storage.loadJournals();
      _entries = _storage.loadEntries();
    });
  }

  double _balance(Journal j) {
    final total = _entries
        .where((e) => e.journalId == j.id)
        .fold(0.0, (s, e) => s + e.inflow - e.outflow);
    return (j.startingBalance ?? 0) + total;
  }

  void _delete(Journal journal) {
    _journals.removeWhere((j) => j.id == journal.id);
    _entries.removeWhere((e) => e.journalId == journal.id);
    _storage.saveJournals(_journals);
    _storage.saveEntries(_entries);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('现金日记账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建日记账',
            onPressed: () => _openJournal(),
          ),
        ],
      ),
      body: _journals.isEmpty
          ? const Center(child: Text('暂无日记账，点击右上角 + 创建'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _journals.length,
              itemBuilder: (_, i) => _buildCard(_journals[i]),
            ),
    );
  }

  Widget _buildCard(Journal journal) {
    final balance = _balance(journal);
    final color = balance < 0
        ? Colors.red
        : journal.startingBalance != null && balance < journal.startingBalance! * 0.2
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(journal.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: journal.startingBalance != null && journal.startingBalance! > 0
                  ? (balance / journal.startingBalance!).clamp(0, 1)
                  : balance > 0 ? balance / 100000 : 0,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              '余额 ¥${_fmt(balance)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(journal),
        ),
        onTap: () => _openJournal(journal: journal),
      ),
    );
  }

  void _openJournal({Journal? journal}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalPage(
          journal: journal,
          entries: _entries.where((e) => e.journalId == journal?.id).toList(),
        ),
      ),
    );
    _load();
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
