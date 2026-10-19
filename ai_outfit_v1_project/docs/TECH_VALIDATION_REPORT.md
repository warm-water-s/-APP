# CurrentOutfitController + AvatarCanvas 技术验证报告

**版本：** TV-004 / 2026-10-18  
**验证范围：** 2D 人物示意、单品选择/锁定/互斥、推荐原子提交、衣橱同步、收藏恢复、本地持久化，以及 V1.0 主要页面的真实 Flutter 渲染。  
**结论：** **Flutter 静态分析、51 项自动化测试、Web 真实浏览器渲染均已实际执行并通过；本地持久化与数据删除 / 导出已实现。Android/iOS 编译与真机、性能测量仍未执行。**

> 本文严格区分“已执行并通过”“已执行但未通过（已修复）”与“未执行”。未执行项不得在验收中写成通过。

## 1. 执行环境

| 项目 | 检查结果 |
|---|---|
| 操作系统 | Windows 11 家庭中文版 64-bit（25H2） |
| Flutter | **3.47.7 stable**（官方 zip，SHA256 校验通过） |
| Dart | **3.13.5**（随 Flutter 3.47.7） |
| Flutter 工程 | `flutter_mvp/`，已生成 `android/`、`ios/`、`web/`、`.metadata`、`pubspec.lock` |
| Chrome | 154.0.8037.98（`flutter doctor` 可用） |
| Edge | 155.0.4283.45（Playwright `channel=msedge` 可用） |
| Android SDK / JDK | **未安装**；`flutter doctor` 报 `Unable to locate Android SDK` |
| 可用设备 | Windows desktop、Chrome、Edge；**无 Android/iOS 设备** |
| Node.js | 22.17.1 |
| Python / Playwright | 3.13.0 / 1.64.0 |
| 本地持久化 | `shared_preferences 2.5.6`（Web / Windows 构建通过；真机未执行） |

环境原始日志：`reports/flutter_doctor.log`。

## 2. 本次实际执行的验证

| 编号 | 内容 | 命令 | 结果 |
|---|---|---|---|
| F01 | 依赖解析 | `flutter pub get` | PASS |
| F02 | 静态分析 | `flutter analyze` | **PASS，No issues found** |
| F03 | Dart / Widget 测试 | `flutter test` | **PASS，51 / 51** |
| F04 | Web 构建 | `flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn` | **PASS**，`build/web` |
| F05 | 真实浏览器渲染与截图 | `python tools/verify_flutter_web.py` | **PASS，11 / 11** |
| C01–C16 | 既有 Node 状态契约镜像 | `node --test tools/verify_state_contract.mjs` | PASS，16 / 16 |
| B01–B12 | 既有 HTML 交互原型 | `python tools/verify_browser.py` | PASS，12 / 12 |

原始日志：

- `reports/flutter_analyze.log`
- `reports/flutter_test.log`（51 项）
- `reports/flutter_web_build.log`
- `reports/flutter_web_smoke_test.log`
- `reports/state_contract_test.log`
- `reports/browser_smoke_test.log`

### 2.1 51 项 Flutter 测试构成

| 测试组 | 数量 | 覆盖 |
|---|---|---|
| `current_outfit_controller_test.dart` T01–T15 | 15 | 初始化、默认锁定、类别错误、非本人衣柜、显式替换、连衣裙互斥、套装完整性、风格切换、推荐原子回滚、删除后恢复、空槽锁定、强制清除 |
| `avatar_canvas_widget_test.dart` W01–W02 | 2 | 六个热点存在且可点击、revision 变化触发重绘 |
| `repositories_test.dart` R01–R09 | 9 | 衣橱增删改查/搜索、收藏幂等、收藏 ID 快照、缺失服装恢复、删除收藏不影响衣服、衣橱与当前穿搭同步、快照不可变 |
| `recommendation_engine_test.dart` E01–E06 | 6 | 空衣橱、只使用衣橱内单品、缺鞋部分搭配、推荐理由引用真实名称、`owned=false` 排除、连衣裙方案互斥 |
| `home_flow_widget_test.dart` W03–W10 | 8 | 首页换装→推荐→换一套→收藏→收藏列表、锁定替换确认、缺失恢复、320px 无溢出、缩略图无热点、空衣橱导入闭环、1.3 倍大字体、隐私页删除本机数据 |
| `persistence_test.dart` P01–P11 | 11 | JSON 往返、重启恢复、清空衣柜不重置、损坏数据回退、存储失败不阻断、收藏顺序、草稿不持久化、SharedPreferences 真读写、存储删除、删除本机数据、导出 JSON |

### 2.2 关键不变量与测试对应

| 不变量 | 验证 |
|---|---|
| I01 六个槽位始终存在 | T01、T09 |
| I02 连衣裙与上衣/下装互斥 | T06、T15、E06 |
| I03 锁定必须有服装 | T13 |
| I04 类别必须与槽位一致 | T03 |
| I05 未知/非本人服装不能加入 | T04、E05 |
| I06 手动选择默认锁定，覆盖需确认参数 | T02、T05、W04 |
| I07 推荐失败不得部分写入 | T10 |
| I08 切换风格不改变衣服 | T09 |
| I09 缺失服装只能恢复为空槽 | T12、R05、W05 |
| I10 完整套装规则 | T07、T08、T11 |

### 2.3 本地持久化验证

实现方式：`shared_preferences` 保存一个带 `version: 1` 的 JSON 快照（衣橱、收藏、偏好、是否看过欢迎页）；当前穿搭草稿**不持久化**。写入经过 120ms 防抖，失败不会阻断 UI，并记录在 `AppState.lastPersistenceError`。

已验证：

- JSON 编解码保留服装来源、URL、备注、季节等可选字段（P01）。
- 重启后恢复衣橱修改、收藏、偏好、欢迎状态（P02、P06）。
- 用户清空衣柜后不会被演示数据重新填充（P03）。
- 损坏 / 版本不兼容数据回退为 `null`（P04）。
- 存储失败不阻断启动，恢复后可继续保存（P05）。
- 当前穿搭草稿不会跨启动恢复（P07）。
- `SharedPreferencesOutfitStorage` 通过 mock 完成一次真实读写（P08）。
- 本机存储支持删除快照（P09）。
- 隐私页“删除本机数据”会清空衣橱、收藏、偏好与当前穿搭，并持久化空快照；重启不会恢复演示衣橱（P10、W10）。
- “导出 JSON”包含衣橱、收藏与偏好，不包含当前穿搭草稿（P11）。
- 包含插件的 Web 构建成功，11/11 渲染检查通过。

**尚未验证：** Android/iOS 真机上 Art 进程重启后的跨启动恢复、应用升级时的 schema 迁移、数据加密与多账号隔离；真机上的导出 / 删除流程也未执行。

## 3. 真实浏览器渲染验证（Flutter Web）

`flutter build web` 成功后，用系统 Edge（Playwright）加载构建产物，在以下视口截图并检查：

| 场景 | 视口 | 结果 |
|---|---|---|
| 首页 2D 换装 | 390 × 844 | PASS |
| 欢迎页 | 390 × 844 | PASS |
| 衣橱列表 | 390 × 844 | PASS |
| 我的穿搭（空态） | 390 × 844 | PASS |
| 我的 / 设置 | 390 × 844 | PASS |
| 首页窄屏 | 320 × 700 | PASS，无溢出 |
| 首页宽屏 | 430 × 900 | PASS |
| 选衣 BottomSheet | 390 × 844 | PASS，通过热点打开并截图 |
| 页面异常 / 控制台错误 | — | 0 / 0 |

截图：

- `reports/flutter_web_home.png`
- `reports/flutter_web_welcome.png`
- `reports/flutter_web_wardrobe.png`
- `reports/flutter_web_outfits.png`
- `reports/flutter_web_profile.png`
- `reports/flutter_web_picker.png`
- `reports/flutter_web_home-320.png`
- `reports/flutter_web_home-430.png`

**限定：**

1. 这是 **Flutter Web** 的真实渲染，不是 Android/iOS 真机截图。
2. Flutter Web 的中文字形依赖运行时字体回退；截图中文字是否完整取决于网络与字体加载，不能作为移动端字体度量证据。
3. 热点语义树在 Web 上可启用，但 `flt-semantics` 未暴露选衣标题节点；弹层通过确定性坐标点击打开，功能正确性由 Widget 测试 W03/W04 保证。
4. 320/390/430 是浏览器视口，不等同于真机安全区、状态栏和系统字体缩放。

## 4. 本次修复的真实问题

首次在 Flutter 3.47.7 上执行时，`flutter analyze` 报出 17 个问题，`flutter test` 有 2 个测试文件加载失败。已修复：

1. `outfits_page.dart` 少一个类闭合括号，导致 `_EmptySaved` 被解析为内部类。
2. `formatSavedTime` 放在使用方之外造成循环/未定义引用，已抽到 `ui/widgets/formatters.dart`。
3. 两处未使用 import（`outfit_state.dart`、`garment_visual.dart`）在 `unused_import: error` 下失败。
4. `const Text('添加${slot.label}')` 对非 const 变量做插值，改为非 const。
5. 窄屏 / Web 字体回退时 Material Chip 标签被裁切，新增 `AppPill` 替换风格、筛选和人物热点。
6. `GarmentSwatch` 内部 `CustomPaint` 在宽松约束下宽度为 0，衣橱卡片只剩一条竖线；改为 `SizedBox.expand` 后恢复服装剪影。
7. 测试中的 `ensureVisible` 无法定位懒加载 ListView 的未构建子项，改用 `scrollUntilVisible`。

修复后 `flutter analyze` 为 0 issue，当前 51 项测试全部通过。

## 5. 未执行 / 不得宣称通过的项

| 项目 | 状态 | 原因 |
|---|---|---|
| `flutter build apk` / `flutter build ios` | **未执行** | 无 Android SDK / JDK；iOS 需 macOS |
| Android/iOS 真机运行 | **未执行** | 无设备、无平台工具链 |
| 320/390/430 真机布局与安全区 | **未验证** | 仅完成 Web 视口与 Widget 测试 |
| 大字体真机 / 屏幕阅读器 | **部分**：Widget 1.3 倍字体通过，TalkBack/VoiceOver 未测 | 无设备 |
| 换装响应 p50 / p95 | **未测量** | 无真机性能采样；仅有测试执行时长 |
| 真实图片上传、抠图、AI 识别 | **未实现** | 当前为手动填写演示导入 |
| 淘宝/天猫授权接口 | **未接入** | 仅校验 URL 并保留来源 |
| 服务端鉴权、数据隔离 | **未实现** | 仓库内无后端；本地仓库不能作为权限依据 |
| 本地持久化 | **已实现（单元 + mock）** | `shared_preferences`；Web 构建通过 |
| 本机数据删除 / 导出 | **已实现（单元 + Widget）** | P09–P11、W10；删除后写入空快照 |
| 真机删除 / 导出 | **未执行** | 无 Android/iOS 设备 |
| 真机跨启动持久化 | **未验证** | 无 Android/iOS 设备；未做进程重启与应用升级测试 |
| 多账号 / 数据加密 | **未实现** | 无账号体系；本地数据未加密 |

## 6. 验收条件对照

| 原定通过条件 | 结果 |
|---|---|
| 1. `flutter analyze` 无问题 | **满足** |
| 2. T01–T15、W01–W02 全部通过 | **满足**，并扩展至 51 项 |
| 3. Android 真机可选六个槽位并刷新人物 | **未执行** |
| 4. 推荐/锁定/保存状态一次流程稳定同步 | **在 Widget 测试 W03 中满足**；真机未执行 |
| 5. 320/390/430px 界面可用 | Web 视口与 Widget 满足；真机未执行 |
| 6. 选衣到绘制响应实际性能 | **未测量** |
| 7. 衣橱 / 收藏跨启动恢复 | **自动化测试满足**（P02/P06/P08）；真机未验证 |
| 8. 本机数据删除 / 导出 | **自动化测试 + Widget 满足**（P09–P11、W10）；真机未执行 |

**阶段判定：** Flutter PoC 的**源码、静态分析、单元/Widget 测试和 Web 渲染**已完成正式验证；**Android/iOS 真机验收仍未完成**，因此不能把“真机已通过”写入发布结论。

## 7. 复现命令

```bash
cd ai_outfit_v1_project/flutter_mvp
flutter pub get
flutter analyze
flutter test

# 真实浏览器截图验证（需要 Edge/Chrome + Playwright）
flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn
cd ..
python tools/verify_flutter_web.py
```

说明：本仓库开发机的 Flutter SDK 位于 `D:\Dev\flutter`，不属于仓库内容；其他机器需自行安装 Flutter 3.47.x 或兼容版本。

## 8. 执行记录

```text
Flutter version: 3.47.7 stable
Dart version: 3.13.5
OS / 机型: Windows 11 25H2；无 Android/iOS 设备
flutter analyze: PASS，0 issue
flutter test: PASS，51 / 51（6s）
flutter build web: PASS
flutter run: 未执行（无 Android/iOS 设备）
Web 渲染截图: 8 张，11/11 检查通过
人物截图: reports/flutter_web_home.png
换装响应 P95: 未测量
已知问题: 无 Android SDK/JDK；真机持久化、导出与删除未验证；真实图片/AI/后端未接入
下一轮结论: 可开始真实 API Repository 与设备验收，不得宣称真机通过
```

## 9. 下一步最小验证

1. 安装 Android SDK + JDK，执行 `flutter build apk --debug` 并在真机/模拟器跑 W03 流程。
2. 在 320/390/430 真机与大字体下复核人物热点和底部弹层。
3. 用 `flutter drive` 或 DevTools 采样换装帧耗时，记录 p50/p95。
4. 在真机上验证应用重启、剪贴板导出与删除流程；补 schema 迁移与多账号隔离。
5. 接入 `WardrobeRepository` 的真实 API 实现，再验证用户隔离与多账号数据边界。
