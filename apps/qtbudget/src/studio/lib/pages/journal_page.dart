import 'package:flutter/material.dart';
import '../models/journal.dart';
import '../models/journal_entry.dart';
import '../models/account_code.dart';
import '../services/storage_service.dart';
import 'account_codes_page.dart';

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
  late TextEditingController _balanceCtrl;
  late final _editing = widget.journal != null;

  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  String? _accountCodeId;

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
    _amtCtrl.dispose();
    super.dispose();
  }

  List<AccountCode> get _accounts => _storage.loadAccountCodes();

  double _balance() {
    final total = widget.entries.fold(0.0, (s, e) => s + e.totalDebit - e.totalCredit);
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
      journals.add(Journal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        startingBalance: double.tryParse(_balanceCtrl.text),
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

    // 如果选了科目，生成标准双行分录；否则用默认规则
    if (_accountCodeId != null) {
      final code = _accounts.firstWhere((c) => c.id == _accountCodeId);
      final isExpense = code.type == AccountType.expense;
      final entry = JournalEntry(
        id: id,
        journalId: journal.id,
        entryDate: DateTime.now(),
        description: _descCtrl.text,
        lines: [
          JournalEntryLine(
            id: '${id}_1',
            accountCodeId: code.id,
            accountName: code.name,
            debit: isExpense ? raw : 0,
            credit: isExpense ? 0 : raw,
            description: _descCtrl.text,
          ),
          JournalEntryLine(
            id: '${id}_2',
            accountCodeId: '-',
            accountName: isExpense ? '银行存款' : '银行存款',
            debit: isExpense ? 0 : raw,
            credit: isExpense ? raw : 0,
            description: '对方科目',
          ),
        ],
      );
      final all = [...widget.entries, entry];
      _storage.saveEntries(all);
    }

    _descCtrl.clear();
    _amtCtrl.clear();
    setState(() => _accountCodeId = null);
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
              decoration: const InputDecoration(labelText: '期初余额（可选）', prefixText: '¥ '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
    final accounts = _accounts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('录入凭证', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('科目管理'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountCodesPage()),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '摘要', isDense: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _accountCodeId,
                    decoration: const InputDecoration(labelText: '科目', isDense: true),
                    items: [
                      if (_accountCodeId == null)
                        const DropdownMenuItem(value: null, child: Text('先选科目')),
                      ...accounts.map((a) =>
                        DropdownMenuItem(value: a.id, child: Text('${a.code} ${a.name}'))),
                    ],
                    onChanged: (v) => setState(() => _accountCodeId = v),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
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
              final balanced = e.isBalanced;
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
                        if (!balanced)
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                        Text(
                          '¥${_fmt(e.totalDebit)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balanced ? Colors.green.shade800 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...e.lines.map((l) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '  ${l.accountName}  ${l.debit > 0 ? "借 ¥${_fmt(l.debit)}" : ""}${l.credit > 0 ? "贷 ¥${_fmt(l.credit)}" : ""}',
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
