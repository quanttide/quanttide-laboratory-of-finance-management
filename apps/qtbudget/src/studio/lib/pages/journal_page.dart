import 'package:flutter/material.dart';
import '../models/journal.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';

class JournalPage extends StatefulWidget {
  final Journal? journal;
  final List<Entry> entries;

  const JournalPage({
    super.key,
    this.journal,
    required this.entries,
  });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _storage = StorageService();

  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late final _editing = widget.journal != null;

  final _descCtrl = TextEditingController();
  final _inflowCtrl = TextEditingController();
  final _outflowCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final j = widget.journal;
    _nameCtrl = TextEditingController(text: j?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: j?.startingBalance?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _descCtrl.dispose();
    _inflowCtrl.dispose();
    _outflowCtrl.dispose();
    super.dispose();
  }

  double _balance() {
    final total = widget.entries.fold(0.0, (s, e) => s + e.inflow - e.outflow);
    return (widget.journal?.startingBalance ?? 0) + total;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final journals = _storage.loadJournals();

    if (_editing) {
      final j = widget.journal!;
      j.name = name;
      j.startingBalance = double.tryParse(_balanceCtrl.text);
      final idx = journals.indexWhere((x) => x.id == j.id);
      if (idx >= 0) journals[idx] = j;
    } else {
      journals.add(
        Journal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          startingBalance: double.tryParse(_balanceCtrl.text),
        ),
      );
    }

    _storage.saveJournals(journals);
    if (mounted) Navigator.pop(context);
  }

  void _addEntry() {
    final inflow = double.tryParse(_inflowCtrl.text) ?? 0;
    final outflow = double.tryParse(_outflowCtrl.text) ?? 0;
    if (inflow <= 0 && outflow <= 0) return;

    final journal = widget.journal;
    if (journal == null) return;

    final entry = Entry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      journalId: journal.id,
      description: _descCtrl.text,
      inflow: inflow,
      outflow: outflow,
      date: DateTime.now(),
    );

    final all = [...widget.entries, entry];
    _storage.saveEntries(all);

    _descCtrl.clear();
    _inflowCtrl.clear();
    _outflowCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? widget.journal!.name : '新建日记账'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo(),
            const SizedBox(height: 16),
            if (_editing) ...[
              _buildEntryForm(),
              const SizedBox(height: 16),
              _buildBalance(),
              const SizedBox(height: 16),
              _buildEntryList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '日记账名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '期初余额（可选）',
                prefixText: '¥ ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
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
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '说明', isDense: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inflowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '收入',
                      isDense: true,
                      prefixText: '+¥ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _outflowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '支出',
                      isDense: true,
                      prefixText: '-¥ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('录入'),
                onPressed: _addEntry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalance() {
    final balance = _balance();
    return Card(
      color: balance < 0 ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前余额', style: TextStyle(fontSize: 14)),
                Text(
                  '¥${_fmt(balance)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: balance < 0 ? Colors.red : Colors.green.shade800,
                  ),
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
                title: Text(e.description.isNotEmpty ? e.description : '无说明'),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (e.inflow > 0)
                        Text(
                          '+¥${_fmt(e.inflow)}',
                          style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (e.outflow > 0)
                        Text(
                          '-¥${_fmt(e.outflow)}',
                          style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
