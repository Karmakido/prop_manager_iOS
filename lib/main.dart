import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const PropManagerApp());

// Change this to adjust the low-stock warning threshold
const int criticalThreshold = 10;

class PropManagerApp extends StatelessWidget {
  const PropManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prop Manager',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const PropListScreen(),
    );
  }
}

// --- Model ---

class PropType {
  String name;
  int cw;
  int ccw;

  PropType({required this.name, this.cw = 20, this.ccw = 20});

  Map<String, dynamic> toJson() => {'name': name, 'cw': cw, 'ccw': ccw};
  factory PropType.fromJson(Map<String, dynamic> json) =>
      PropType(name: json['name'], cw: json['cw'] ?? 20, ccw: json['ccw'] ?? 20);
}

// --- Storage ---

class PropStore {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/props.json');
  }

  static Future<List<PropType>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final data = jsonDecode(await file.readAsString()) as List;
      return data.map((e) => PropType.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<PropType> props) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(props.map((p) => p.toJson()).toList()));
  }
}

// --- Main Screen ---

class PropListScreen extends StatefulWidget {
  const PropListScreen({super.key});

  @override
  State<PropListScreen> createState() => _PropListScreenState();
}

class _PropListScreenState extends State<PropListScreen> {
  List<PropType> _props = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final props = await PropStore.load();
    setState(() { _props = props; _loading = false; });
  }

  Future<void> _save() => PropStore.save(_props);

  bool get _hasWarning =>
      _props.any((p) => p.cw < criticalThreshold || p.ccw < criticalThreshold);

  void _decrement(PropType prop, bool isCW) {
    setState(() {
      if (isCW) {
        if (prop.cw > 0) prop.cw--;
      } else {
        if (prop.ccw > 0) prop.ccw--;
      }
    });
    _save();
  }

  void _increment(PropType prop, bool isCW) {
    setState(() {
      if (isCW) {
        prop.cw++;
      } else {
        prop.ccw++;
      }
    });
    _save();
  }

  Future<void> _addProp() async {
    final nameCtrl = TextEditingController();
    final cwCtrl = TextEditingController(text: '20');
    final ccwCtrl = TextEditingController(text: '20');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Prop-Typ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'z.B. HQ 5x4.3x3')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: cwCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CW Start'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: ccwCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CCW Start'))),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hinzufügen')),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _props.add(PropType(
          name: nameCtrl.text.trim(),
          cw: int.tryParse(cwCtrl.text) ?? 20,
          ccw: int.tryParse(ccwCtrl.text) ?? 20,
        ));
      });
      _save();
    }
  }

  Future<void> _deleteProp(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: Text('${_props[index].name} wirklich entfernen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nein')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _props.removeAt(index));
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prop Manager'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Warning banner
          if (_hasWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade900,
              child: const Row(children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('PROPS UNTER 10! Nachbestellen!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
              ]),
            ),

          // Prop list
          Expanded(
            child: _props.isEmpty
                ? const Center(child: Text('Keine Props angelegt.\nTippe auf + um zu starten.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _props.length,
                    itemBuilder: (ctx, i) => _PropCard(
                      prop: _props[i],
                      onCW: () => _decrement(_props[i], true),
                      onCCW: () => _decrement(_props[i], false),
                      onCWAdd: () => _increment(_props[i], true),
                      onCCWAdd: () => _increment(_props[i], false),
                      onDelete: () => _deleteProp(i),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProp,
        icon: const Icon(Icons.add),
        label: const Text('Prop-Typ'),
      ),
    );
  }
}

class _PropCard extends StatelessWidget {
  final PropType prop;
  final VoidCallback onCW;
  final VoidCallback onCCW;
  final VoidCallback onCWAdd;
  final VoidCallback onCCWAdd;
  final VoidCallback onDelete;

  const _PropCard({
    required this.prop,
    required this.onCW,
    required this.onCCW,
    required this.onCWAdd,
    required this.onCCWAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cwLow = prop.cw < criticalThreshold;
    final ccwLow = prop.ccw < criticalThreshold;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(prop.name, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              // CW
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: cwLow ? Colors.red.shade900 : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('CW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cwLow ? Colors.white : null)),
                    Text('${prop.cw}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cwLow ? Colors.white : prop.cw == 0 ? Colors.grey : null)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton.filled(
                        onPressed: onCWAdd,
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(backgroundColor: cwLow ? Colors.green.shade700 : null, minimumSize: const Size(36, 36)),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: prop.cw > 0 ? onCW : null,
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(backgroundColor: cwLow ? Colors.red : null, minimumSize: const Size(36, 36)),
                      ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              // CCW
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: ccwLow ? Colors.red.shade900 : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('CCW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ccwLow ? Colors.white : null)),
                    Text('${prop.ccw}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ccwLow ? Colors.white : prop.ccw == 0 ? Colors.grey : null)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton.filled(
                        onPressed: onCCWAdd,
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(backgroundColor: ccwLow ? Colors.green.shade700 : null, minimumSize: const Size(36, 36)),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: prop.ccw > 0 ? onCCW : null,
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(backgroundColor: ccwLow ? Colors.red : null, minimumSize: const Size(36, 36)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
