import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../domain/garment.dart';
import '../../theme/app_theme.dart';
import '../widgets/garment_visual.dart';

const _palette = <String>[
  '#F0ECE4',
  '#FFFFFF',
  '#D9C9B6',
  '#BBA88F',
  '#BDA98E',
  '#A57D5F',
  '#88A6C0',
  '#9AB5BF',
  '#41475D',
  '#4A4B50',
  '#464750',
  '#292723',
  '#889F90',
  '#618575',
  '#BB7066',
  '#B9834B',
];

/// UI-10 AI 识别确认 / 服装编辑。
///
/// 当前不接入真实 AI 识别，进入页面时的预填值明确标记为“演示识别结果”。
class GarmentEditorPage extends StatefulWidget {
  const GarmentEditorPage({
    super.key,
    required this.appState,
    this.initial,
    this.initialSlot,
    this.sourceType = GarmentSource.manual,
    this.sourceUrl,
  });

  final AppState appState;
  final Garment? initial;
  final GarmentSlot? initialSlot;
  final GarmentSource sourceType;
  final String? sourceUrl;

  @override
  State<GarmentEditorPage> createState() => _GarmentEditorPageState();
}

class _GarmentEditorPageState extends State<GarmentEditorPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _subcategoryController;
  late GarmentSlot _slot;
  late String _color;
  late Set<String> _styleIds;
  late Set<String> _seasons;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _subcategoryController =
        TextEditingController(text: initial?.subcategory ?? '');
    _slot = initial?.slot ?? widget.initialSlot ?? GarmentSlot.top;
    _color = initial?.colorHex ?? _palette.first;
    _styleIds = <String>{...?initial?.styleIds};
    _seasons = <String>{...?initial?.seasons};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写服装名称')),
      );
      return;
    }
    final subcategory = _subcategoryController.text.trim();
    final draft = Garment(
      id: widget.initial?.id ?? '',
      name: name,
      slot: _slot,
      colorHex: _color,
      subcategory: subcategory.isEmpty ? _slot.label : subcategory,
      styleIds: _styleIds,
      seasons: _seasons,
      sourceType: widget.initial?.sourceType ?? widget.sourceType,
      sourceUrl: widget.initial?.sourceUrl ?? widget.sourceUrl,
      note: widget.initial?.note,
    );
    final Garment saved;
    if (_isEditing) {
      widget.appState.wardrobe.update(draft);
      saved = draft;
    } else {
      saved = widget.appState.wardrobe.add(draft);
    }
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final preview = Garment(
      id: 'preview',
      name: _nameController.text.trim().isEmpty
          ? '新的${_slot.label}'
          : _nameController.text.trim(),
      slot: _slot,
      colorHex: _color,
      subcategory: _subcategoryController.text.trim().isEmpty
          ? _slot.label
          : _subcategoryController.text.trim(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑服装' : '确认服装信息'),
      ),
      body: ListView(
        key: const Key('garment-editor-scroll'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                GarmentSwatch(
                  garment: preview,
                  width: 58,
                  height: 76,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        preview.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${preview.slot.label} · ${preview.subcategory}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_isEditing ? '编辑' : '导入'}来源：'
                        '${(widget.initial?.sourceType ?? widget.sourceType).label}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '演示模式：图片识别、抠图与真实图片上传尚未接入。'
                    '下方字段是演示预填，可完全手动修改。',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('名称（必填）'),
          TextField(
            key: const Key('garment-name'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '例如：米白色基础衬衫'),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('主类别'),
          DropdownButtonFormField<GarmentSlot>(
            key: const Key('garment-slot'),
            initialValue: _slot,
            items: <DropdownMenuItem<GarmentSlot>>[
              for (final slot in GarmentSlot.values)
                DropdownMenuItem<GarmentSlot>(
                  value: slot,
                  child: Text(slot.label),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _slot = value);
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('子类别'),
          TextField(
            key: const Key('garment-subcategory'),
            controller: _subcategoryController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '例如：衬衫 / 牛仔裤'),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('主颜色'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final hex in _palette)
                GestureDetector(
                  key: Key('color-$hex'),
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: parseGarmentColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _color == hex ? AppColors.primary : Colors.black12,
                        width: _color == hex ? 2.5 : 1,
                      ),
                    ),
                    child: _color == hex
                        ? Icon(
                            Icons.check,
                            size: 17,
                            color: ThemeData.estimateBrightnessForColor(
                                      parseGarmentColor(hex),
                                    ) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black54,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const _FieldLabel('风格标签（可多选）'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final entry in styleNames.entries)
                FilterChip(
                  key: Key('style-tag-${entry.key}'),
                  label: Text(entry.value),
                  selected: _styleIds.contains(entry.key),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _styleIds.add(entry.key);
                      } else {
                        _styleIds.remove(entry.key);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          const _FieldLabel('适用季节（可多选）'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final entry in seasonNames.entries)
                FilterChip(
                  key: Key('season-${entry.key}'),
                  label: Text(entry.value),
                  selected: _seasons.contains(entry.key),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _seasons.add(entry.key);
                      } else {
                        _seasons.remove(entry.key);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('garment-save'),
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(_isEditing ? '保存修改' : '保存到我的衣橱'),
          ),
          const SizedBox(height: 10),
          const Text(
            '名称与主类别为必填项。未识别到的字段由你手动补充，不会生成虚构的高置信度标签。',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
