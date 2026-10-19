# 文件索引 / 阅读优先级

本文件供人类与 AI 辅助编程工具快速定位项目资料。路径相对 `ai_outfit_v1_project/`。

| 相对路径 | 内容 | 优先级 |
|---|---|---|
| `README.md` | 项目状态、运行方式、测试证据 | 1 |
| `docs/AI_HANDOFF.md` | 后续 AI 接续约定与当前边界 | 2 |
| `docs/PRD_V1.0.md` | 需求范围、功能编号和业务约束 | 3 |
| `docs/UI_UX_V1.0.md` | 页面布局、交互、Design Tokens、实现状态 | 4 |
| `prototype/interactive_prototype.html` | 16 页面/界面浏览器交互原型 | 5 |
| `prototype/preview_6screens.png` | 六个主要页面视觉预览 | 5 |
| `docs/ARCHITECTURE_V1.0.md` | 分层、AppState/Repository、状态与绘制架构 | 6 |
| `docs/INTERFACES_V1.0.md` | 数据/服务 API 建议契约（草案） | 6 |
| `docs/TECH_VALIDATION_REPORT.md` | TV-004：已执行 / 未执行的真实边界 | 7 |
| `docs/TEST_MATRIX.md` | 分层测试矩阵与结果 | 7 |
| `docs/DEV_TASKS.md` | 任务状态与下一步 | 8 |
| `docs/adr/ADR-001-state-controller.md` | 不可变状态 / 单写入控制器 | 8 |
| `docs/adr/ADR-002-avatar-layer.md` | 2D 模板示意而非真实试衣 | 8 |
| `docs/adr/ADR-003-app-state-and-repositories.md` | AppState 与内存 Repository 边界 | 8 |
| `CHANGELOG.md` | 变更记录（v0.3.1 起含数据删除/导出） | 9 |

## Flutter 源码

| 相对路径 | 内容 |
|---|---|
| `flutter_mvp/pubspec.yaml` / `pubspec.lock` | 工程定义与锁定版本 |
| `flutter_mvp/android/`、`ios/`、`web/` | `flutter create` 生成的平台工程 |
| `flutter_mvp/lib/main.dart` | 正式启动入口 |
| `flutter_mvp/lib/main_web_demo.dart` | Web 截图/冒烟入口（URL 参数） |
| `flutter_mvp/lib/app.dart` | MaterialApp、四 Tab AppShell |
| `flutter_mvp/lib/theme/app_theme.dart` | Design Tokens / ThemeData |
| `flutter_mvp/lib/domain/garment.dart` | 服装、槽位、来源、季节 |
| `flutter_mvp/lib/domain/outfit_state.dart` | 不可变 CurrentOutfit |
| `flutter_mvp/lib/domain/current_outfit_controller.dart` | 唯一业务写入口 |
| `flutter_mvp/lib/domain/outfit_recommendation.dart` | 推荐候选 + 缺失类别 |
| `flutter_mvp/lib/domain/saved_outfit.dart` | 收藏快照 / 指纹 / 缺失槽位 |
| `flutter_mvp/lib/data/demo_catalog.dart` | 15 件演示服装与风格字典 |
| `flutter_mvp/lib/data/demo_recommendation_engine.dart` | 本地确定性推荐（非 AI） |
| `flutter_mvp/lib/data/wardrobe_repository.dart` | 内存衣橱仓库 |
| `flutter_mvp/lib/data/saved_outfits_repository.dart` | 内存收藏仓库（幂等） |
| `flutter_mvp/lib/data/outfit_storage.dart` | 本地持久化：versioned JSON / shared_preferences / 内存测试实现 |
| `flutter_mvp/lib/data/app_state.dart` | 应用组合根 + 自动持久化 |
| `flutter_mvp/lib/ui/avatar_canvas.dart` | 2D 人物 CustomPainter + 六热点 |
| `flutter_mvp/lib/ui/pages/home_page.dart` | 首页换装 / 风格 / 推荐 / 保存 |
| `flutter_mvp/lib/ui/pages/wardrobe_page.dart` | 衣橱列表 / 搜索 / 筛选 |
| `flutter_mvp/lib/ui/pages/garment_detail_page.dart` | 服装详情 |
| `flutter_mvp/lib/ui/pages/garment_editor_page.dart` | 导入确认 / 编辑表单 |
| `flutter_mvp/lib/ui/pages/import_method_page.dart` | 拍照 / 相册 / 链接导入演示 |
| `flutter_mvp/lib/ui/pages/outfits_page.dart` | 收藏列表 |
| `flutter_mvp/lib/ui/pages/outfit_detail_page.dart` | 收藏详情 / 穿上这套 |
| `flutter_mvp/lib/ui/pages/profile_page.dart` | 我的 / 统计 |
| `flutter_mvp/lib/ui/pages/style_preferences_page.dart` | 风格偏好 |
| `flutter_mvp/lib/ui/pages/privacy_page.dart` | 隐私说明 + 导出 JSON / 删除本机数据 |
| `flutter_mvp/lib/ui/pages/welcome_page.dart` / `login_page.dart` | 欢迎 / 演示登录 |
| `flutter_mvp/lib/ui/widgets/app_pill.dart` | 胶囊按钮（风格 / 筛选 / 热点） |
| `flutter_mvp/lib/ui/widgets/wardrobe_picker_sheet.dart` | 选衣 BottomSheet |
| `flutter_mvp/lib/ui/widgets/garment_visual.dart` | 服装剪影绘制 / 颜色解析 |
| `flutter_mvp/lib/ui/widgets/confirm_dialog.dart` | 统一二次确认 |
| `flutter_mvp/lib/ui/widgets/formatters.dart` | 时间格式化 |
| `flutter_mvp/assets/README.md` | 素材目录约定（当前无二进制素材） |

## 测试

| 相对路径 | 内容 |
|---|---|
| `flutter_mvp/test/current_outfit_controller_test.dart` | T01–T15 |
| `flutter_mvp/test/avatar_canvas_widget_test.dart` | W01–W02 |
| `flutter_mvp/test/repositories_test.dart` | R01–R09 |
| `flutter_mvp/test/recommendation_engine_test.dart` | E01–E06 |
| `flutter_mvp/test/home_flow_widget_test.dart` | W03–W09 |
| `flutter_mvp/test/persistence_test.dart` | P01–P08 |
| `tools/verify_state_contract.mjs` | C01–C16（Node 契约镜像） |
| `tools/verify_browser.py` | B01–B12（HTML 原型） |
| `tools/verify_flutter_web.py` | WEB01–WEB11（Flutter Web 真渲染） |

## 报告与证据

| 相对路径 | 内容 |
|---|---|
| `reports/flutter_analyze.log` | `flutter analyze` 原始输出 |
| `reports/flutter_test.log` | 51 项 Flutter 测试原始输出 |
| `reports/flutter_web_build.log` | Web 构建日志 |
| `reports/flutter_web_smoke_test.log` | Web 渲染检查 11/11 |
| `reports/flutter_doctor.log` | Flutter 环境检查（Android SDK 缺失） |
| `reports/state_contract_test.log` | Node 16/16 |
| `reports/browser_smoke_test.log` | HTML 原型 12/12 |
| `reports/flutter_web_*.png` | Flutter Web 真实截图（首页 / 欢迎 / 衣橱 / 收藏 / 我的 / 320 / 430 / 选衣） |
| `reports/browser_*_verified.png` | HTML 原型历史截图（非 Flutter） |
| `project_state.json` | 机器可读状态摘要 |
| `file_manifest.json` | 文件清单与哈希（2026-10-18 重新生成） |

## 冲突处理与更新优先级

**产品范围：** PRD > UI/UX > 代码。  
**技术决策：** ADR / 架构 > 代码历史注释。  
**验证真相：** 实际运行日志 > 技术报告摘要 > 文件说明；不能把未执行测试写成通过。  
**命名原则：** 需求 `FR-*`、验收 `TC-*`、工程测试 `T/W/R/E/C/B/WEB-*`。
