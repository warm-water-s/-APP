import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../domain/garment.dart';
import '../../theme/app_theme.dart';
import '../widgets/garment_visual.dart';
import 'garment_editor_page.dart';

/// UI-07 添加方式选择。
class ImportMethodPage extends StatelessWidget {
  const ImportMethodPage({
    super.key,
    required this.appState,
    this.initialSlot,
  });

  final AppState appState;
  final GarmentSlot? initialSlot;

  Future<void> _open(BuildContext context, Widget page) async {
    final result = await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(builder: (_) => page),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加衣服')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          const Text(
            '选择一种导入方式',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'V1.0 演示版本不会上传真实照片，也不会访问第三方商品接口；'
            '保存的服装是本机演示数据。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _MethodCard(
            key: const Key('import-camera'),
            icon: Icons.photo_camera_outlined,
            title: '手机拍照',
            subtitle: '拍摄一件衣服后进入识别确认流程',
            onTap: () => _open(
              context,
              ImageImportPage(
                appState: appState,
                initialSlot: initialSlot,
                source: GarmentSource.camera,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            key: const Key('import-gallery'),
            icon: Icons.photo_library_outlined,
            title: '从相册选择',
            subtitle: '选择已有照片，裁剪到单件服装',
            onTap: () => _open(
              context,
              ImageImportPage(
                appState: appState,
                initialSlot: initialSlot,
                source: GarmentSource.photo,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            key: const Key('import-link'),
            icon: Icons.link,
            title: '商品链接导入',
            subtitle: '粘贴淘宝/天猫链接；无授权时手动补充图片与信息',
            onTap: () => _open(
              context,
              LinkImportPage(appState: appState, initialSlot: initialSlot),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '所有自动字段都可以在下一步手动修改。导入失败不会丢弃已填写内容。',
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

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.avatarStage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// UI-08 图片导入（演示占位）。
class ImageImportPage extends StatelessWidget {
  const ImageImportPage({
    super.key,
    required this.appState,
    required this.source,
    this.initialSlot,
  });

  final AppState appState;
  final GarmentSource source;
  final GarmentSlot? initialSlot;

  Future<void> _continue(BuildContext context) async {
    final result = await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(
        builder: (_) => GarmentEditorPage(
          appState: appState,
          initialSlot: initialSlot,
          sourceType: source,
        ),
      ),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(source == GarmentSource.camera ? '拍照导入' : '相册导入')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const GarmentSwatch(
                  garment: null,
                  width: 74,
                  height: 96,
                  borderRadius: 14,
                ),
                const SizedBox(height: 12),
                Text(
                  source == GarmentSource.camera ? '相机区域' : '照片预览区域',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '演示模式未申请相机/相册权限',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '当前版本没有接入真实图片选择、裁剪与 AI 抠图。继续后会创建一条手动填写的演示记录，'
              '不会伪造“识别成功”。正式版本将使用系统相册/相机权限，失败时可重试且保留草稿。',
              style: TextStyle(fontSize: 11, height: 1.55),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('demo-image-continue'),
            onPressed: () => _continue(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('手动填写并继续'),
          ),
        ],
      ),
    );
  }
}

/// UI-09 商品链接导入。只做 URL 格式校验，明确说明未接入平台授权接口。
class LinkImportPage extends StatefulWidget {
  const LinkImportPage({
    super.key,
    required this.appState,
    this.initialSlot,
  });

  final AppState appState;
  final GarmentSlot? initialSlot;

  @override
  State<LinkImportPage> createState() => _LinkImportPageState();
}

class _LinkImportPageState extends State<LinkImportPage> {
  final TextEditingController _urlController = TextEditingController();
  String? _error;
  bool _accepted = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _urlController.text.trim();
    final uri = Uri.tryParse(text);
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    setState(() {
      _error = valid ? null : '请输入有效的 http/https 商品链接';
      _accepted = valid;
    });
  }

  Future<void> _continue() async {
    final result = await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(
        builder: (_) => GarmentEditorPage(
          appState: widget.appState,
          initialSlot: widget.initialSlot,
          sourceType: GarmentSource.link,
          sourceUrl: _urlController.text.trim(),
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品链接导入')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          const Text(
            '粘贴商品链接',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '仅保存来源链接并进入手动确认；不会自动抓取商品详情。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('link-url'),
            controller: _urlController,
            keyboardType: TextInputType.url,
            onChanged: (_) {
              if (_accepted || _error != null) {
                setState(() {
                  _accepted = false;
                  _error = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'https://item.taobao.com/...',
              errorText: _error,
              suffixIcon: IconButton(
                key: const Key('link-paste'),
                tooltip: '粘贴',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _urlController.text = data!.text!;
                    _parse();
                  }
                },
                icon: const Icon(Icons.content_paste),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('link-parse'),
            onPressed: _parse,
            icon: const Icon(Icons.travel_explore),
            label: const Text('解析链接（演示）'),
          ),
          const SizedBox(height: 18),
          if (_accepted) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.link, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '链接格式有效',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _urlController.text.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '未接入淘宝/天猫授权接口，无法读取商品图片与属性。'
                    '你可以继续手动填写服装信息；来源链接会保留在记录中。',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('link-continue'),
              onPressed: _continue,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('继续手动填写'),
            ),
          ] else
            const Text(
              '提示：正式版本需要合法的平台授权，不能把绕过授权的抓取作为主方案。',
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
