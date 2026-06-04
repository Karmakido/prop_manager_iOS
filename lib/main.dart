import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const PropManagerApp());

// ============================================================
// Settings Store
// ============================================================

class AppSettings {
  ThemeMode themeMode;
  int criticalThreshold;

  AppSettings({this.themeMode = ThemeMode.dark, this.criticalThreshold = 10});

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'criticalThreshold': criticalThreshold,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values.byName(
          json['themeMode'] as String? ?? 'dark',
        ),
        criticalThreshold: (json['criticalThreshold'] as num?)?.toInt() ?? 10,
      );

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }

  static Future<AppSettings> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return AppSettings();
      return AppSettings.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> save() async {
    final file = await _file();
    await file.writeAsString(jsonEncode(toJson()));
  }
}

// ============================================================
// Model
// ============================================================

class PropType {
  String name;
  int cw;
  int ccw;
  String? orderLink;

  PropType({
    required this.name,
    this.cw = 20,
    this.ccw = 20,
    this.orderLink,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'cw': cw,
        'ccw': ccw,
        if (orderLink != null && orderLink!.isNotEmpty) 'orderLink': orderLink,
      };

  factory PropType.fromJson(Map<String, dynamic> json) => PropType(
        name: json['name'] as String,
        cw: (json['cw'] as num?)?.toInt() ?? 20,
        ccw: (json['ccw'] as num?)?.toInt() ?? 20,
        orderLink: json['orderLink'] as String?,
      );
}

// ============================================================
// Storage
// ============================================================

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
      return data.map((e) => PropType.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<PropType> props) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(props.map((p) => p.toJson()).toList()));
  }
}

// ============================================================
// App Root
// ============================================================

class PropManagerApp extends StatefulWidget {
  const PropManagerApp({super.key});

  @override
  State<PropManagerApp> createState() => _PropManagerAppState();
}

class _PropManagerAppState extends State<PropManagerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    setState(() {
      _settings = s;
      _loaded = true;
    });
  }

  Future<void> _openSettings() async {
    final result = await _navigatorKey.currentState?.push<AppSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: _settings),
      ),
    );
    if (result != null) {
      setState(() => _settings = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Prop Manager',
      themeMode: _settings.themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: PropListScreen(
        criticalThreshold: _settings.criticalThreshold,
        onOpenSettings: _openSettings,
      ),
    );
  }
}

// ============================================================
// Settings Screen
// ============================================================

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  late TextEditingController _thresholdCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settings.themeMode;
    _thresholdCtrl = TextEditingController(
      text: '${widget.settings.criticalThreshold}',
    );
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.settings.themeMode = _themeMode;
    widget.settings.criticalThreshold =
        int.tryParse(_thresholdCtrl.text) ?? widget.settings.criticalThreshold;
    widget.settings.save();
    setState(() => _saved = true);
    Navigator.pop(context, widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Theme ──
          Text('Theme', style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Hell'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dunkel'),
                icon: Icon(Icons.dark_mode),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_brightness),
              ),
            ],
            selected: {_themeMode},
            onSelectionChanged: (v) => setState(() => _themeMode = v.first),
          ),

          const SizedBox(height: 32),

          // ── Critical threshold ──
          Text('Kritischer Bestand', style: t.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Warnung wenn CW oder CCW unter diesen Wert fallen',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Schwellwert',
              suffixText: 'Stück',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 40),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Speichern'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Main Screen
// ============================================================

class PropListScreen extends StatefulWidget {
  final int criticalThreshold;
  final VoidCallback onOpenSettings;

  const PropListScreen({
    super.key,
    required this.criticalThreshold,
    required this.onOpenSettings,
  });

  @override
  State<PropListScreen> createState() => _PropListScreenState();
}

class _PropListScreenState extends State<PropListScreen> {
  List<PropType> _props = [];
  bool _loading = true;

  int get _threshold => widget.criticalThreshold;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PropListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.criticalThreshold != widget.criticalThreshold) {
      setState(() {}); // re-render with new threshold colours
    }
  }

  Future<void> _load() async {
    final props = await PropStore.load();
    setState(() {
      _props = props;
      _loading = false;
    });
  }

  Future<void> _save() => PropStore.save(_props);

  bool get _hasWarning =>
      _props.any((p) => p.cw < _threshold || p.ccw < _threshold);

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

  // ── Add / Edit dialog ──

  Future<PropType?> _showPropDialog({PropType? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cwCtrl =
        TextEditingController(text: '${existing?.cw ?? 20}');
    final ccwCtrl =
        TextEditingController(text: '${existing?.ccw ?? 20}');
    final linkCtrl = TextEditingController(text: existing?.orderLink ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Neuer Prop-Typ' : 'Bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. HQ 5x4.3x3',
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: cwCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CW Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ccwCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CCW Start'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Bestell-Link (optional)',
                  hintText: 'z.B. https://banggood.com/...',
                  prefixIcon: Icon(Icons.shopping_cart, size: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(existing == null ? 'Hinzufügen' : 'Speichern'),
          ),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      return PropType(
        name: nameCtrl.text.trim(),
        cw: int.tryParse(cwCtrl.text) ?? 20,
        ccw: int.tryParse(ccwCtrl.text) ?? 20,
        orderLink: linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
      );
    }
    return null;
  }

  Future<void> _addProp() async {
    final prop = await _showPropDialog();
    if (prop != null) {
      setState(() => _props.add(prop));
      _save();
    }
  }

  Future<void> _editProp(int index) async {
    final updated = await _showPropDialog(existing: _props[index]);
    if (updated != null) {
      setState(() => _props[index] = updated);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _props.removeAt(index));
      _save();
    }
  }

  // ── Open order link ──

  Future<void> _openLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;

    final toLaunch = uri.hasScheme ? uri : Uri.parse('https://$rawUrl');
    try {
      await launchUrl(toLaunch, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konnte Link nicht öffnen')),
        );
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prop Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning banner
          if (_hasWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade900,
              child: Row(children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PROPS UNTER $_threshold! Nachbestellen!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]),
            ),

          // Prop list
          Expanded(
            child: _props.isEmpty
                ? Center(
                    child: Text(
                      'Keine Props angelegt.\nTippe auf + um zu starten.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _props.length,
                    itemBuilder: (ctx, i) => _PropCard(
                      prop: _props[i],
                      threshold: _threshold,
                      onCW: () => _decrement(_props[i], true),
                      onCCW: () => _decrement(_props[i], false),
                      onCWAdd: () => _increment(_props[i], true),
                      onCCWAdd: () => _increment(_props[i], false),
                      onEdit: () => _editProp(i),
                      onDelete: () => _deleteProp(i),
                      onOpenLink: (url) => _openLink(url),
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

// ============================================================
// Prop Card
// ============================================================

class _PropCard extends StatelessWidget {
  final PropType prop;
  final int threshold;
  final VoidCallback onCW;
  final VoidCallback onCCW;
  final VoidCallback onCWAdd;
  final VoidCallback onCCWAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String url) onOpenLink;

  const _PropCard({
    required this.prop,
    required this.threshold,
    required this.onCW,
    required this.onCCW,
    required this.onCWAdd,
    required this.onCCWAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cwLow = prop.cw < threshold;
    final ccwLow = prop.ccw < threshold;
    final hasLink = prop.orderLink != null && prop.orderLink!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(children: [
              Expanded(
                child: Text(prop.name, style: t.textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Bearbeiten',
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),

            // ── Order link ──
            if (hasLink)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => onOpenLink(prop.orderLink!),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart, size: 15, color: t.colorScheme.primary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Bestellen',
                            style: TextStyle(
                              color: t.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── CW / CCW counters ──
            const SizedBox(height: 4),
            Row(children: [
              _CounterBox(
                label: 'CW',
                count: prop.cw,
                low: cwLow,
                onAdd: onCWAdd,
                onRemove: onCW,
              ),
              const SizedBox(width: 16),
              _CounterBox(
                label: 'CCW',
                count: prop.ccw,
                low: ccwLow,
                onAdd: onCCWAdd,
                onRemove: onCCW,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Reusable counter box ──

class _CounterBox extends StatelessWidget {
  final String label;
  final int count;
  final bool low;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CounterBox({
    required this.label,
    required this.count,
    required this.low,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: low
              ? Colors.red.shade900
              : t.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Label + count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: low ? Colors.white : null,
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: low
                        ? Colors.white
                        : count == 0
                            ? Colors.grey
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filled(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: low ? Colors.green.shade700 : null,
                    minimumSize: const Size(44, 44),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: count > 0 ? onRemove : null,
                  icon: const Icon(Icons.remove, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: low ? Colors.red : null,
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
