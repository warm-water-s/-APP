# AI 智能衣橱 APP · V1.0

> **版本：** 2026-10-18 · `v0.3.1`  
> **状态：** PRD 与 UI/UX 已归档；**Flutter 静态分析、51 项自动化测试、Web 真实渲染截图已通过**；衣橱 / 收藏 / 偏好已保存到本机，并提供导出与删除入口；**Android/iOS 真机与性能仍未验证**（本机无 Android SDK/JDK）。  
> **产品定位：** 以用户真实衣橱为数据来源的 2D 虚拟换装 MVP。当前衣橱、推荐与收藏是**本机演示数据**，不连接真实后端、AI 或电商接口。

## 1. 交付内容

| 成果 | 文件 | 状态 |
|---|---|---|
| 产品需求文档 | [`docs/PRD_V1.0.md`](docs/PRD_V1.0.md) | 已归档（需求基线） |
| UI/UX 规范 | [`docs/UI_UX_V1.0.md`](docs/UI_UX_V1.0.md) | 已归档，附实现状态 |
| 可交互 HTML 原型 | [`prototype/interactive_prototype.html`](prototype/interactive_prototype.html) | 浏览器流程已验证 12/12 |
| Flutter 工程 | [`flutter_mvp/`](flutter_mvp/) | **analyze 0 issue；51/51 测试通过；Web 构建通过** |
| 技术验证报告 | [`docs/TECH_VALIDATION_REPORT.md`](docs/TECH_VALIDATION_REPORT.md) | TV-004，明确列出已执行/未执行 |
| 状态契约验证 | [`tools/verify_state_contract.mjs`](tools/verify_state_contract.mjs) | Node 16/16 PASS |
| Flutter Web 渲染验证 | [`tools/verify_flutter_web.py`](tools/verify_flutter_web.py) | Edge 无头浏览器 11/11 PASS，附截图 |
| 后续接续说明 | [`docs/AI_HANDOFF.md`](docs/AI_HANDOFF.md) | 已更新到 v0.3.1 |
| 接口与任务 | [`docs/INTERFACES_V1.0.md`](docs/INTERFACES_V1.0.md)、[`docs/DEV_TASKS.md`](docs/DEV_TASKS.md) | 接口为草案；任务已更新状态 |

文件索引：[`docs/FILE_INDEX.md`](docs/FILE_INDEX.md)。

## 2. 产品范围

`已有服装导入 → 服装标签确认 → 固定上衣/下装并锁定 → 选择风格 → 只从本人衣橱推荐 → 2D 小人展示 → 局部替换 → 保存与恢复`

第一版**不做**：真实 AI 真人试衣、3D 服装建模、电商购物结算、社交社区。  
2D 人物仅为穿搭示意图；推荐不得把用户未拥有的衣服当作已拥有。

## 3. 当前可用的功能（本地演示）

- **首页**：2D 人物、六个服装热点、风格选择、当前穿搭锁定、演示推荐、换一套、保存、缺失类别提示。
- **衣橱**：搜索 / 类别筛选、服装卡片、详情、编辑、删除、添加流程（拍照 / 相册 / 商品链接均为演示流程）。
- **穿搭**：收藏列表、详情、缺失提示、穿上这套、删除收藏。
- **我的**：统计、风格偏好、隐私说明、新手引导。
- **隐私与数据**：导出本机数据 JSON；二次确认后删除衣橱、收藏、偏好与当前穿搭。
- **欢迎 / 演示登录**：不发送真实短信、不创建账号。

明确边界：

- 衣橱 / 收藏 / 偏好通过 `shared_preferences` 保存在**本机**，卸载应用会清除；当前穿搭草稿仍只在内存中。
- “删除本机数据”会写入空快照，重启后不会恢复演示衣橱；真机上的剪贴板导出与删除流程尚未验证。
- 图片导入不会读取真实相册或相机，也不会做 AI 识别。
- 商品链接只校验 URL 并保存来源字符串，不访问淘宝/天猫。
- 推荐是本地确定性规则，不是训练过的模型。
- Android/iOS 真机上的跨启动恢复尚未验证。

## 4. 运行与验证

需要 Flutter 3.47.x（本项目在 3.47.7 / Dart 3.13.5 上验证）。

```bash
cd flutter_mvp
flutter pub get
flutter analyze          # 应为 No issues found
flutter test             # 51 tests
flutter run              # 需连接 Android/iOS 设备或模拟器
```

Web 演示与截图：

```bash
cd flutter_mvp
flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn
cd ..
python -m pip install playwright       # 首次
python tools/verify_flutter_web.py     # 使用系统 Edge，截图写入 reports/
```

HTML 原型：

```bash
node --test tools/verify_state_contract.mjs
python tools/verify_browser.py
```

## 5. 测试证据

| 项目 | 结果 | 日志 / 截图 |
|---|---|---|
| `flutter analyze` | PASS，0 issue | `reports/flutter_analyze.log` |
| `flutter test` | PASS，51/51 | `reports/flutter_test.log` |
| Flutter Web 构建 | PASS | `reports/flutter_web_build.log` |
| Edge 渲染检查 | PASS，11/11 | `reports/flutter_web_smoke_test.log` |
| Flutter Web 截图 | 8 张 | `reports/flutter_web_*.png` |
| Node 状态契约 | PASS，16/16 | `reports/state_contract_test.log` |
| HTML 原型 | PASS，12/12 | `reports/browser_smoke_test.log` |
| Android/iOS 真机 | **未执行** | 无 Android SDK/JDK 与设备 |
| 性能 p50/p95 | **未测量** | — |

**不得把未执行的真机/性能项写成已通过。**

## 6. 如何使用和修改项目

1. 先读 [`AGENTS.md`](../AGENTS.md)（仓库根目录）和 [`docs/AI_HANDOFF.md`](docs/AI_HANDOFF.md)。
2. 产品需求先改 PRD，再同步 UI/UX。
3. 数据结构 / API 改动更新 `docs/INTERFACES_V1.0.md` 与架构文档。
4. 代码改动在 `flutter_mvp/` 进行，并补充 `test/`。
5. 每轮更新 `CHANGELOG.md`、`docs/DEV_TASKS.md`、验证报告。
6. 重要决策写 ADR（见 `docs/adr/`）。

## 7. 建议的下一步

1. 安装 Android SDK + JDK，完成真机/模拟器验收与换装性能测量（M0-05 / M0-07）。
2. 在真机验证本地数据跨启动恢复、剪贴板导出与删除流程，并补 schema 迁移策略。
3. 接入图片选择与裁剪（`image_picker` 等），保留手动确认兜底。
4. 接入后端鉴权、服装 CRUD、收藏 API，并验证用户数据隔离（M2）。
