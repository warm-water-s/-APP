# 给后续 AI / 开发者的项目接续说明

> **第一阅读入口：** 根目录 `README.md`，然后按本文件顺序读取。  
> **项目：** AI 智能衣橱（AI Outfit）V1.0，标准 2D 小人换装 MVP。  
> **最后更新：** 2026-10-18 · v0.3.1

## 1. 先读这些文件（按顺序）

1. `README.md` — 总体交付状态、运行方式与测试证据。
2. `docs/PRD_V1.0.md` — **产品范围权威来源**。
3. `docs/UI_UX_V1.0.md` — 16 个页面、布局与交互；配合 `prototype/interactive_prototype.html`。
4. `docs/ARCHITECTURE_V1.0.md` — 分层、AppState / Repository、状态与人物渲染。
5. `docs/TECH_VALIDATION_REPORT.md` — 已执行 / 未执行的严格边界（TV-004）。
6. `docs/INTERFACES_V1.0.md` — 建议数据与 API 契约。
7. `docs/TEST_MATRIX.md` / `docs/DEV_TASKS.md` — 测试矩阵与当前待办。
8. `docs/adr/*.md`、`CHANGELOG.md` — 已做决定与变更记录。

## 2. 当前唯一确定的 MVP 核心目标

> “选中自己的一件衣服 → 选择风格 → 只从本人衣柜中推荐其他单品 → 2D 人物示意展示 → 用户局部更换/锁定 → 保存与恢复。”

**绝不改变这些前提：**
- 2D 虚拟人物是近似示意，不能假装真实试衣。
- 正式推荐不能使用当前用户衣柜中不存在的服装。
- 连衣裙与普通上衣、下装默认互斥。
- 推荐不得覆盖已锁定单品；错误的推荐不得部分修改状态。
- 展示、衣服卡片和收藏读取同一 `CurrentOutfit`。
- 淘宝商品链接自动获取详情必须通过合法平台授权，失败要可手动上传。
- 仓库中的 AI、登录、收藏/衣柜后端均**尚未真正集成**；衣橱/收藏/偏好保存在本机，不会上传云端。

## 3. 当前源码结构（v0.3.1）

```text
flutter_mvp/lib/
├── main.dart                     # 正式启动入口
├── main_web_demo.dart            # 仅 Web 截图/冒烟验证入口（URL 参数）
├── app.dart                      # MaterialApp + 四 Tab AppShell
├── theme/app_theme.dart          # Design tokens
├── domain/
│   ├── garment.dart              # 服装 / 槽位 / 来源
│   ├── outfit_state.dart         # 不可变 CurrentOutfit
│   ├── outfit_recommendation.dart
│   ├── saved_outfit.dart         # 收藏快照、缺失槽位
│   └── current_outfit_controller.dart  # 唯一业务写入口
├── data/
│   ├── demo_catalog.dart         # 15 件演示服装
│   ├── demo_recommendation_engine.dart # 本地确定性推荐（非 AI）
│   ├── wardrobe_repository.dart  # 内存衣橱仓库
│   ├── saved_outfits_repository.dart   # 内存收藏仓库（幂等）
│   ├── outfit_storage.dart       # 本地持久化（shared_preferences + JSON）
│   └── app_state.dart            # 组合根：衣橱 + 收藏 + 当前穿搭 + 持久化
└── ui/
    ├── avatar_canvas.dart        # 2D 人物 CustomPainter + 六热点
    ├── pages/                    # 首页、衣橱、穿搭、我的、导入、编辑等
    └── widgets/                  # AppPill、选衣弹层、服装剪影、确认框
```

平台工程：`android/`、`ios/`、`web/` 由 `flutter create` 生成；`pubspec.lock` 已提交以便复现。

## 4. 真实验证边界（2026-10-18）

已执行并通过：

- `flutter analyze`：0 issue。
- `flutter test`：**51 / 51**（T01–T15、W01–W10、R01–R09、E01–E06、P01–P11）。
- `flutter build web`：成功；Edge 无头浏览器 **11 / 11** 渲染检查，截图在 `reports/flutter_web_*.png`。
- Node 状态契约 16/16；HTML 原型 12/12（回归）。
- 本地持久化：`shared_preferences` + versioned JSON，P01–P11 通过。
- 数据管理：隐私页可导出 JSON、删除本机衣橱 / 收藏 / 偏好并写入空快照（W10）。

**未执行：**

- `flutter build apk` / iOS 构建、Android/iOS 真机运行（本机无 Android SDK/JDK）。
- 真机 320/390/430px、安全区、屏幕阅读器。
- 换装性能 p50/p95。
- 真机上的跨启动恢复、剪贴板导出、删除流程、schema 升级迁移、本地数据加密与多账号隔离。
- 真实图片上传、AI 识别、淘宝授权、后端鉴权。

任何后来继续此项目的 AI 都应先重跑 `flutter analyze` 与 `flutter test`，再更改源码。遇到错误应修复、保留测试，不要为“使测试通过”而删除关键业务约束。

## 5. 接续任务时应遵守

- 先检查 Git 当前变更和本文档版本，再修改。
- 保持 PRD 需求 ID 和 UI 页面编号不变；新增功能用新编号。
- 改动数据契约先更新 `docs/INTERFACES_V1.0.md`。
- 改动业务规则先更新 PRD 和 ADR。
- 修改 `CurrentOutfitController` 时同步完善 `flutter_mvp/test/`。
- 别直接覆盖 `prototype/` 的历史 HTML；如要迭代，另建版本。
- 衣橱 / 收藏的 Repository 是后端替换点；不要把演示数据当真实用户数据。
- 修改 `outfit_storage.dart` 的 JSON 结构时，必须同步 `INTERFACES` / `ARCHITECTURE` 并补充 P 测试。
- 数据删除必须写入空快照，不能让下次启动重新填充演示衣橱。
- 每轮开发完成更新 `CHANGELOG.md`、`docs/TECH_VALIDATION_REPORT.md`、`docs/DEV_TASKS.md` 和测试结果。

## 6. 已知风险 / 技术债

| 风险 | 现状 | 下一步 |
|---|---|---|
| 真机持久化未验证 | 仅单元/mock 与 Web 构建 | 真机重启、升级迁移、加密与删除/导出流程 |
| 图片导入是演示流程 | 未申请权限、无真实图片 | 接入 `image_picker` + 裁剪 + 上传 |
| 服装剪影不是真实素材 | CustomPainter 轮廓 + 主色 | 制定 `GarmentVisualAsset` 与分层素材 |
| Web 字体回退依赖网络 | 截图中文可能失败 | 正式版可考虑内置中文字体子集 |
| 无真机证据 | 仅 Web + Widget | 安装 Android SDK 后补验收 |
| 后端与鉴权缺失 | 无 API | 按 INTERFACES 实现并做越权测试 |

## 7. 可复制给下一次 AI 的指令

```text
这是我正在开发的 AI 智能衣橱 APP V1.0 项目。
请先阅读仓库根目录 AGENTS.md，然后按 docs/AI_HANDOFF.md 的顺序阅读 README、PRD、UI/UX、架构、接口、验证报告与源码。
不要扩展成 3D 或真人试衣。
先运行 flutter analyze / flutter test，确认 51 项测试仍然通过，再开始修改。
修改前说明影响的文件和业务不变量；修改后更新测试、验证报告、DEV_TASKS 与 CHANGELOG。
如果某项测试因环境限制无法执行，必须标记“未执行”。
本次具体任务是：[在这里描述希望增加或修改的内容]
```
