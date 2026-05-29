import 'package:flutter/material.dart';
import '../models/journal.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';

class JournalPage extends StatefulWidget {
  final Journal? journal;
  final List<JournalEntry> entries;

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
  late final _editing = widget.journal != null;

  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  bool _isCredit = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.journal?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  double get _balance => widget.entries.fold(0.0, (s, e) => s + e.totalDebit - e.totalCredit);

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final journals = _storage.loadJournals();
    if (_editing) {
      widget.journal!.name = name;
    } else {
      journals.add(Journal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      ));
    }
    _storage.saveJournals(journals);
    if (mounted) Navigator.pop(context);
  }

  void _addEntry() {
    final raw = double.tryParse(_amtCtrl.text);
    if (raw == null || raw <= 0) return;
    final journal = widget.journal;
    if (journal == null) return;

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = JournalEntry(
      id: id,
      journalId: journal.id,
      entryDate: DateTime.now(),
      description: _descCtrl.text,
      lines: [
        JournalEntryLine(
          id: '${id}_1',
          debit: _isCredit ? 0 : raw,
          credit: _isCredit ? raw : 0,
          description: _descCtrl.text,
        ),
      ],
    );
    _storage.saveEntries([...widget.entries, entry]);

    _descCtrl.clear();
    _amtCtrl.clear();
    setState(() => _isCredit = false);
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
              _buildBalanceCard(),
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
        child: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: '日记账名称'),
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
            const Text('录入凭证', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '摘要', isDense: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('借方')),
                    ButtonSegment(value: true, label: Text('贷方')),
                  ],
                  selected: {_isCredit},
                  onSelectionChanged: (v) => setState(() => _isCredit = v.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '金额', isDense: true, prefixText: '¥ '),
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

  Widget _buildBalanceCard() {
    return Card(
      color: _balance < 0 ? Colors.red.shade50 : Colors.green.shade50,
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
                  '¥${_fmt(_balance)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _balance < 0 ? Colors.red : Colors.green.shade800,
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
            Text('凭证列表（${entries.length}）',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ...entries.reversed.take(50).map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.description.isNotEmpty ? e.description : '无摘要',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '¥${_fmt(e.totalDebit)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...e.lines.map((l) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '${l.debit > 0 ? "借 ¥${_fmt(l.debit)}" : "贷 ¥${_fmt(l.credit)}"}  ${l.description}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )),
                    const Divider(height: 12),
                  ],
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
