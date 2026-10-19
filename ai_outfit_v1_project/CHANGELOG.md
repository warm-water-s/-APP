# CHANGELOG — AI 智能衣橱 V1.0

## 2026-10-18 · v0.3.1 — 本机数据删除与导出

### 新增

- 隐私与数据说明页新增“本机数据管理”：
  - **导出 JSON**：把当前衣橱、收藏、偏好快照复制到剪贴板（P11）。
  - **删除本机数据**：二次确认后清空衣橱、收藏、偏好与当前穿搭，并写入空快照；重启后不会恢复演示衣橱（P09/P10/W10）。
- `OutfitStorage.clear()`：`SharedPreferencesOutfitStorage` 删除存储 key，`InMemoryOutfitStorage` 清空并计数。
- `AppState.exportData()` / `AppState.clearPersonalData()`。
- 新增测试 P09–P11、W10。

### 验证（本次真正执行）

- `flutter analyze`：**No issues found**。
- `flutter test`：**51 / 51 通过**。
- `flutter build web`：PASS；Edge 渲染检查 **11 / 11**。
- **未验证：** 真机上的剪贴板导出与删除流程、schema 迁移、本地数据加密。

### 变更

- 版本号 `0.3.1+4`。
- 隐私页由纯说明改为可执行的数据管理入口。
- 更新 `TECH_VALIDATION_REPORT`（TV-004）、`TEST_MATRIX`、`DEV_TASKS`、`ARCHITECTURE`、`UI_UX`、`README`、`AI_HANDOFF`、`FILE_INDEX`、`project_state.json`。

## 2026-10-18 · v0.3.0 — 本地持久化

### 新增

- 衣橱、收藏、风格偏好与“已看过欢迎页”状态通过 `shared_preferences 2.5.6` 保存到本机；版本化 JSON（`version: 1`），当前穿搭草稿仍不持久化。
- `AppState.load()`：启动时恢复本地数据；首次启动写入演示衣橱；本地数据损坏或版本不兼容时回退到演示数据。
- 写入采用 120ms 防抖，存储失败不阻断 UI，并记录到 `AppState.lastPersistenceError`。
- 新增 `lib/data/outfit_storage.dart`（存储接口、SharedPreferences 实现、内存实现、JSON 编解码）。
- 新增 `test/persistence_test.dart` P01–P08。
- 用户清空衣柜后不会被演示数据重新填充（`has_wardrobe` 标记）。

### 验证（本次真正执行）

- `flutter analyze`：**No issues found**。
- `flutter test`：**47 / 47 通过**（新增 P01–P08）。
- `flutter build web`：PASS；Edge 渲染检查 **11 / 11**。
- **未验证：** Android/iOS 真机进程重启后的恢复、schema 升级迁移、本地数据加密与多账号隔离。

### 变更

- `lib/main.dart` 改为异步加载本地状态后再启动。
- 界面文案由“本次运行 / 关闭即清空”改为“保存在本机”；隐私说明同步。
- 版本号 `0.3.0+3`。
- 更新 `TECH_VALIDATION_REPORT`（TV-003）、`TEST_MATRIX`、`DEV_TASKS`、`ARCHITECTURE`、`README`、`AI_HANDOFF`、`FILE_INDEX`、`project_state.json`。

## 2026-10-18 · v0.2.0 — Flutter 实测通过 + Milestone 1 主要页面

### 验证（本次真正执行）

- 安装并使用 Flutter **3.47.7 stable** / Dart 3.13.5；生成 `android/`、`ios/`、`web/` 平台目录与 `pubspec.lock`。
- `flutter analyze`：**No issues found**（修复 17 个初始诊断）。
- `flutter test`：**39 / 39 通过**，包括 T01–T15、W01–W09、R01–R09、E01–E06。
- `flutter build web`：PASS；用 Edge 无头浏览器完成 **11 / 11** 渲染与截图检查。
- 回归执行既有 Node 契约 16/16、HTML 浏览器 12/12。
- **未执行：** Android/iOS 编译与真机、性能采样。原因：本机无 Android SDK/JDK 与设备。

### 新增功能与页面

- 四 Tab AppShell：首页 / 衣橱 / 穿搭 / 我的，统一 Theme tokens（背景、表面、主色、描边、圆角）。
- 首页：2D 人物六槽位、风格选择、当前穿搭锁定、演示推荐、换一套、保存、缺失类别提示。
- 衣橱：搜索、类别筛选、双列卡片、空态、添加流程（拍照 / 相册 / 商品链接的演示流程）、服装详情、编辑、删除。
- 穿搭：收藏列表、穿搭详情、缺失单品提示、穿上这套、删除收藏（不删除衣服）。
- 我的：单品 / 收藏 / 偏好统计、风格偏好、隐私说明、新手引导、关于演示版本。
- 欢迎页与演示登录页。
- 新增 `AppPill` 胶囊控件；新增 `GarmentShapePainter` 服装剪影卡片，修复 Web / 窄屏 Chip 标签裁切与空卡片问题。

### 领域与数据层

- `Garment` 增加季节、来源、来源 URL、备注、版型、图案等可选字段与 `copyWith`。
- 新增 `SavedOutfit`：收藏快照、指纹去重、缺失槽位计算。
- 新增 `WardrobeRepository`、`SavedOutfitsRepository`、`AppState`（ADR-003）；衣橱变化会同步移除当前穿搭中的失效单品。
- 推荐结果增加 `missingSlots` / `isComplete`，理由引用真实单品名称；缺鞋时返回部分方案而不是虚构单品。
- **持久化未实现：** 衣橱、收藏、偏好均只保存在本次运行内存中，界面明确标注演示数据。

### 测试与工具

- 新增 `test/repositories_test.dart`、`test/recommendation_engine_test.dart`、`test/home_flow_widget_test.dart`。
- 新增 `tools/verify_flutter_web.py`：构建产物 + Edge/Playwright 的渲染截图与错误检查。
- 新增 Web 截图日志与 8 张真实渲染截图到 `reports/`。
- `tools/verify_browser.py` 支持本机 Chrome/Edge（Playwright channel）。

### 文档

- 重写 `docs/TECH_VALIDATION_REPORT.md`（TV-002），严格区分已执行与未执行。
- 更新 `docs/TEST_MATRIX.md`、`docs/DEV_TASKS.md`、`docs/ARCHITECTURE_V1.0.md`、`docs/UI_UX_V1.0.md`（实现状态）、`docs/AI_HANDOFF.md`、`README.md`、`docs/FILE_INDEX.md`、`project_state.json`。
- 新增 `docs/adr/ADR-003-app-state-and-repositories.md`。

### 变更 / 删除

- `flutter_mvp/lib/main.dart` 由单页 PoC 改为正式启动入口（`runApp(const AiOutfitApp())`）；原 PoC 页面功能被首页、衣橱、收藏等页面取代，AvatarCanvas 与 CurrentOutfitController 保留并扩展。
- 删除控制器测试中未使用的 `outfit_state.dart` import；无业务测试被删除。

## 2026-10-18 · 资料归档与技术验证初版

- 将此前聊天中的 PRD V1.0 整理成 `docs/PRD_V1.0.md` 文件级归档版。
- 归档既有 `docs/UI_UX_V1.0.md`、HTML 交互原型与核心页面预览。
- 创建 `CurrentOutfit`、`CurrentOutfitController`、`OutfitRecommendation` 与 Garment 领域层。
- 创建 2D `AvatarCanvas` Flutter `CustomPainter` 样例，支持六个服装槽位入口。
- 创建简单 Flutter 演示页：选衣、锁定、风格、演示推荐、收藏。
- 新增 Dart / Flutter 单元和 Widget 测试源码（**未运行**，缺 SDK）。
- 通过 Node 独立状态契约测试 16/16。
- 通过 Chromium HTML 端到端测试 12/12。
- 增补架构、接口、测试矩阵、ADR、AI 接续说明和开发任务清单。

## 2026-10-17 · 产品和 UI/UX 基线

- 通过对话明确第一版采用「2D 虚拟换装数字衣橱」。
- 完成 PRD V1.0 的对话版本。
- 完成 UI/UX V1.0 规范、HTML 可交互原型和页面预览。
