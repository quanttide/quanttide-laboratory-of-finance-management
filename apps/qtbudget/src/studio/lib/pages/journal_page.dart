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

  // 新增凭证表单
  final _entryDateCtrl = TextEditingController();
  final _entryDescCtrl = TextEditingController();
  final _lines = <_LineData>[];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.journal?.name ?? '');
    final now = DateTime.now();
    _entryDateCtrl.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _entryDateCtrl.dispose();
    _entryDescCtrl.dispose();
    for (final l in _lines) {
      l.amtCtrl.dispose();
      l.descCtrl.dispose();
    }
    super.dispose();
  }

  double get _totalDebit =>
      _lines.where((l) => l.type == LineType.debit).fold(0, (s, l) => s + (double.tryParse(l.amtCtrl.text) ?? 0));
  double get _totalCredit =>
      _lines.where((l) => l.type == LineType.credit).fold(0, (s, l) => s + (double.tryParse(l.amtCtrl.text) ?? 0));
  double get _diff => _totalDebit - _totalCredit;

  void _addLine({LineType type = LineType.debit}) {
    setState(() => _lines.add(_LineData(id: DateTime.now().microsecondsSinceEpoch.toString(), type: type)));
  }

  void _removeLine(_LineData line) {
    setState(() {
      line.amtCtrl.dispose();
      line.descCtrl.dispose();
      _lines.remove(line);
    });
  }

  double _debit(JournalEntry e) => e.lines.where((l) => l.type == LineType.debit).fold(0.0, (s, l) => s + l.amount);
  double _credit(JournalEntry e) => e.lines.where((l) => l.type == LineType.credit).fold(0.0, (s, l) => s + l.amount);
  bool _balanced(JournalEntry e) {
    final d = _debit(e), c = _credit(e);
    return d > 0 && d == c;
  }

  double _balance() {
    return widget.entries.fold(0.0, (s, e) => s + _debit(e) - _credit(e));
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final journals = _storage.loadJournals();
    if (_editing) {
      final idx = journals.indexWhere((j) => j.id == widget.journal!.id);
      if (idx >= 0) journals[idx] = widget.journal!.copyWith(name: name);
    } else {
      journals.add(Journal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      ));
    }
    _storage.saveJournals(journals);
    if (mounted) Navigator.pop(context);
  }

  void _saveEntry() {
    if (_lines.isEmpty) return;
    final journal = widget.journal;
    if (journal == null) return;

    final now = DateTime.now();
    final entry = JournalEntry(
      id: now.microsecondsSinceEpoch.toString(),
      journalId: journal.id,
      createdAt: now,
      description: _entryDescCtrl.text,
      lines: _lines.map((l) => JournalEntryLine(
        id: l.id,
        type: l.type,
        amount: double.tryParse(l.amtCtrl.text) ?? 0,
        description: l.descCtrl.text,
        createdAt: now,
      )).toList(),
    );

    _storage.saveEntries([...widget.entries, entry]);

    _entryDescCtrl.clear();
    for (final l in _lines) {
      l.amtCtrl.clear();
      l.descCtrl.clear();
    }
    setState(() => _lines.clear());
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
    final unbalanced = _diff != 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('新增凭证', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加行'),
                  onPressed: () => _addLine(),
                ),
              ],
            ),
            const Divider(),
            TextField(
              controller: _entryDescCtrl,
              decoration: const InputDecoration(labelText: '凭证摘要', isDense: true),
            ),
            const SizedBox(height: 8),
            // 表头
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('借贷', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(flex: 2, child: Text('金额', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(flex: 4, child: Text('说明', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                const SizedBox(width: 32),
              ],
            ),
            const Divider(height: 8),
            // 行
            ..._lines.asMap().entries.map((e) => _buildLineRow(e.key, e.value)),
            if (_lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('暂无分录行，点击"添加行"', style: TextStyle(color: Colors.grey))),
              ),
            // 合计
            if (_lines.isNotEmpty) ...[
              const Divider(),
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('合计', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('¥${_fmt(_totalDebit)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('¥${_fmt(_totalCredit)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _diff == 0 ? '✓ 平衡' : '差额 ¥${_fmt(_diff.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _diff == 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (unbalanced && _lines.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text('借贷不平', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('保存凭证'),
                  onPressed: _saveEntry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineRow(int index, _LineData line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${index + 1}.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
          SizedBox(
            width: 60,
            child: SegmentedButton<LineType>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(value: LineType.debit, label: Text('借', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: LineType.credit, label: Text('贷', style: TextStyle(fontSize: 12))),
              ],
              selected: {line.type},
              onSelectionChanged: (v) => setState(() => line.type = v.first),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: line.amtCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                hintText: '金额',
                border: const OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: line.descCtrl,
              decoration: const InputDecoration(isDense: true, hintText: '说明', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () => _removeLine(line),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
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
            Text('凭证列表（${entries.length}）',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ...entries.reversed.take(50).map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                        if (!_balanced(e))
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                        Text(
                          '借 ¥${_fmt(_debit(e))}  贷 ¥${_fmt(_credit(e))}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...e.lines.map((l) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              l.type == LineType.debit ? '借' : '贷',
                              style: TextStyle(
                                color: l.type == LineType.debit ? Colors.green.shade800 : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(l.type == LineType.debit ? '借' : '贷',
                                style: TextStyle(
                                  color: l.type == LineType.debit ? Colors.green.shade800 : Colors.red,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          Text('¥${_fmt(l.amount)}', // JournalEntryLine.amount
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )),
                    const Divider(height: 8),
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

class _LineData {
  final String id;
  LineType type;
  final TextEditingController amtCtrl;
  final TextEditingController descCtrl;

  _LineData({required this.id, required this.type})
      : amtCtrl = TextEditingController(),
        descCtrl = TextEditingController();
}
