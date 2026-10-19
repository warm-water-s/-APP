import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';

/// UI-16 隐私与数据说明。
///
/// 必须如实说明：当前版本没有真实后端、没有图片上传、没有第三方 AI 处理。
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, required this.appState});

  final AppState appState;

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final json = appState.exportData();
    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(
      SnackBar(content: Text('已复制本机数据 JSON（${json.length} 字符）')),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmAction(
      context,
      title: '删除本机数据？',
      message: '将删除衣橱、收藏、风格偏好和当前穿搭草稿。此操作不可撤销，'
          '但不会影响演示说明文字与 APP 本身。',
      confirmLabel: '删除',
    );
    if (!confirmed || !context.mounted) return;

    await appState.clearPersonalData();
    if (!context.mounted) return;
    final error = appState.lastPersistenceError;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null ? '本机数据已删除' : '内存已清空，但本机存储写入失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私与数据说明')),
      body: ListView(
        key: const Key('privacy-scroll'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: <Widget>[
          const _Section(
            icon: Icons.photo_outlined,
            title: '照片',
            body: '当前演示版本不申请相册或相机权限，也不会读取、上传任何真实照片。'
                '“拍照导入 / 相册导入”只演示流程，保存的是你手动填写的本地演示记录。',
          ),
          const _Section(
            icon: Icons.auto_awesome_outlined,
            title: 'AI 服务',
            body: '当前没有接入任何图像识别或推荐模型。页面中的“智能搭配”是固定规则的本地演示算法，'
                '推荐结果全部来自本机演示衣橱，不会发送到第三方。',
          ),
          const _Section(
            icon: Icons.link,
            title: '商品信息',
            body: '商品链接导入只校验 URL 格式并保留来源字符串，不会访问淘宝/天猫接口、'
                '不会抓取商品图片或价格。正式版本必须先取得合法平台授权。',
          ),
          const _Section(
            icon: Icons.account_circle_outlined,
            title: '账号与数据',
            body: '当前没有登录、服务器或云同步。衣橱、偏好和收藏保存在本机应用数据中，'
                '不会上传到云端。下方提供导出与删除入口；正式版本还需要账号注销与'
                '服务端数据删除能力。',
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                    Icon(
                      Icons.storage_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '本机数据管理',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '导出会把衣橱与收藏快照复制为 JSON；删除会清空衣橱、收藏、偏好、'
                  '欢迎页状态和当前穿搭，并写入一个空衣橱快照。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('privacy-export'),
                        onPressed: () => _export(context),
                        icon: const Icon(Icons.copy_all_outlined, size: 17),
                        label: const Text('导出 JSON'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const Key('privacy-clear'),
                        onPressed: () => _clear(context),
                        icon: const Icon(Icons.delete_outline, size: 17),
                        label: const Text('删除本机数据'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '正式发布前需完成：隐私政策、用户协议、图片处理说明、第三方服务清单、'
            '账号注销与服务端数据删除，以及服务端用户数据隔离测试。',
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
