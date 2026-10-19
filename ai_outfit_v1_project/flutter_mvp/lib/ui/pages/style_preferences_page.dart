import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../theme/app_theme.dart';

/// UI-15 风格偏好设置。
class StylePreferencesPage extends StatefulWidget {
  const StylePreferencesPage({super.key, required this.appState});

  final AppState appState;

  @override
  State<StylePreferencesPage> createState() => _StylePreferencesPageState();
}

class _StylePreferencesPageState extends State<StylePreferencesPage> {
  late final Set<String> _selected = <String>{
    ...widget.appState.preferredStyles,
  };

  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    widget.appState.setPreferredStyles(_selected);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('偏好已保存到本机')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('风格偏好')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          const Text(
            '你喜欢哪些风格？',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '可多选。偏好会影响后续推荐排序；不选择也可以正常使用全部风格。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: <Widget>[
              for (final entry in styleNames.entries)
                FilterChip(
                  key: Key('pref-${entry.key}'),
                  label: Text(entry.value),
                  selected: _selected.contains(entry.key),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selected.add(entry.key);
                      } else {
                        _selected.remove(entry.key);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('pref-save'),
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('保存偏好'),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('pref-clear'),
            onPressed: () => setState(_selected.clear),
            child: const Text('清除全部偏好'),
          ),
        ],
      ),
    );
  }
}
