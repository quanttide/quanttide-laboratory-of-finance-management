import 'package:flutter/material.dart';
import '../models/account_code.dart';
import '../services/storage_service.dart';

class AccountCodesPage extends StatefulWidget {
  const AccountCodesPage({super.key});

  @override
  State<AccountCodesPage> createState() => _AccountCodesPageState();
}

class _AccountCodesPageState extends State<AccountCodesPage> {
  final _storage = StorageService();
  late List<AccountCode> _codes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _codes = _storage.loadAccountCodes());
  }

  void _save() => _storage.saveAccountCodes(_codes);

  void _add() {
    showDialog(
      context: context,
      builder: (ctx) => _CodeFormDialog(
        onSave: (code) { setState(() => _codes.add(code)); _save(); },
      ),
    );
  }

  void _edit(AccountCode code) {
    showDialog(
      context: context,
      builder: (ctx) => _CodeFormDialog(
        existing: code,
        onSave: (updated) {
          setState(() {
            final idx = _codes.indexWhere((c) => c.id == code.id);
            if (idx >= 0) _codes[idx] = updated;
          });
          _save();
        },
      ),
    );
  }

  void _delete(AccountCode code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除科目「${code.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() => _codes.removeWhere((c) => c.id == code.id));
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('科目管理')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _codes.isEmpty
          ? const Center(child: Text('暂无科目，点击右下角 + 添加'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _codes.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  _codes.insert(newIndex, _codes.removeAt(oldIndex));
                });
                _save();
              },
              itemBuilder: (_, i) {
                final code = _codes[i];
                final label = code.type.name;
                return Card(
                  key: ValueKey(code.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: i, child: const Icon(Icons.drag_handle),
                    ),
                    title: Text('${code.code} ${code.name}'),
                    subtitle: Text(label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _edit(code),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _delete(code),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CodeFormDialog extends StatefulWidget {
  final AccountCode? existing;
  final void Function(AccountCode) onSave;
  const _CodeFormDialog({this.existing, required this.onSave});

  @override
  State<_CodeFormDialog> createState() => _CodeFormDialogState();
}

class _CodeFormDialogState extends State<_CodeFormDialog> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _type = e?.type ?? AccountType.expense;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? '编辑科目' : '新增科目'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(labelText: '科目编码', hintText: '如 1001'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '科目名称', hintText: '如 银行存款'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: '科目类型'),
            items: AccountType.values.map((t) =>
              DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final code = _codeCtrl.text.trim();
            final name = _nameCtrl.text.trim();
            if (code.isEmpty || name.isEmpty) return;
            widget.onSave(AccountCode(
              id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              code: code,
              name: name,
              type: _type,
            ));
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
