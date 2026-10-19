# Flutter 工程 — AI 智能衣橱 V1.0（本地演示）

本目录是 V1.0 的 Flutter 应用工程，已从“单页技术 PoC”扩展为四 Tab 的本地演示版本。
**所有衣橱、收藏、推荐数据都在内存中，不连接真实后端 / AI / 电商。**

## 工程结构

- `lib/domain/`：服装槽位、不可变 `CurrentOutfit`、收藏快照、推荐结构、单写入控制器。
- `lib/data/`：演示衣柜、确定性演示推荐、内存衣橱 / 收藏仓库、本地持久化、`AppState` 组合根。
- `lib/ui/avatar_canvas.dart`：2D `CustomPainter` 人物 + 六个换装热点。
- `lib/ui/pages/`：首页、衣橱、服装详情 / 编辑、导入、收藏、我的、欢迎 / 登录。
- `lib/ui/widgets/`：选衣弹层、胶囊按钮、服装剪影、确认框等。
- `lib/main.dart`：正式启动入口。
- `lib/main_web_demo.dart`：仅用于 Web 截图 / 冒烟验证（通过 URL 参数跳过欢迎页或打开 Tab）。
- `test/`：51 项控制器、仓库、推荐、持久化、数据管理和 Widget 测试。

## 本地运行

需要 Flutter 3.47.x（本仓库在 3.47.7 / Dart 3.13.5 上验证）。

```bash
flutter --version
flutter pub get
flutter analyze
flutter test
flutter run          # 需 Android/iOS 设备或模拟器
```

Web 演示：

```bash
flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn
cd ..
python tools/verify_flutter_web.py
```

## 已实际验证

- `flutter analyze`：No issues found。
- `flutter test`：51 / 51 通过。
- `flutter build web`：通过；Edge 无头浏览器 11 / 11（截图见 `../reports/flutter_web_*.png`）。
- 本地持久化：`shared_preferences` + versioned JSON；P01–P11 通过。
- 数据管理：隐私页导出 JSON、删除本机数据；W10 通过。
- **未验证：** Android/iOS 构建与真机、真机跨启动恢复与删除/导出、性能、真实图片/AI。本机没有 Android SDK/JDK，因此没有 `flutter build apk` 记录。

## 行为契约

- 对任何衣服 ID 先校验是否存在于当前 closet 且所属类别正确。
- `dress` 与普通 `top/bottom` 互斥；手动选衣默认锁定；覆盖锁定需明确确认。
- `applyRecommendation` 在任何校验失败时不得部分提交。
- 每次成功写入更新 `CurrentOutfit.revision` 并通过 `ChangeNotifier` 通知依赖层。
- 删除衣服会同步从当前穿搭中移除；收藏恢复时缺失单品保持空槽。
- `AvatarCanvas` 只做示意渲染，商品原图不会自动贴到人身上。

## 当前限制

- 无登录、AI、云端数据、电商接口、真实图片模板。
- 衣橱 / 收藏 / 偏好通过 `shared_preferences` 保存在本机；当前穿搭草稿不持久化。
- 隐私页提供导出 JSON 与删除本机数据；删除后写入空快照，重启不恢复演示衣橱。
- 本地数据未加密、未按账号隔离；真机跨启动、导出、删除与升级迁移未验证。
- 小人颜色 / 轮廓为示意，不模拟身体尺寸；服装卡片使用类别剪影占位。
- 真机视觉、性能与无障碍待测试。

详细状态见 `../docs/TECH_VALIDATION_REPORT.md`。
