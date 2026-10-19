# 测试矩阵 V1.2

> **分层说明：**
> - `C` = Node 独立业务契约镜像；`B` = HTML 交互原型；二者不能替代 Flutter 测试。
> - `T` = 真实 Dart 控制器测试；`R` = Repository / AppState；`E` = 演示推荐引擎；`P` = 本地持久化；`W` = Flutter Widget / 页面流程。
> - `WEB` = Flutter Web 构建产物在真实浏览器中的渲染与截图检查。

**最后执行：** 2026-10-18 · Flutter 3.47.7 / Dart 3.13.5

| ID | 场景 | 测试层 | 结果 |
|---|---|---|---|
| C01–C16 | 状态不变量、锁定、连衣裙互斥、缺失衣服和原子更新 | Node 契约镜像 | **已执行，16/16 通过** |
| B01–B12 | HTML 人物、热点、选衣、推荐、收藏、导入和个人中心 | Chromium / Playwright | **已执行，12/12 通过** |
| T01–T15 | 控制器初始化、选衣、锁定、互斥、推荐原子性、恢复 | `flutter test` | **已执行，15/15 通过** |
| W01–W02 | AvatarCanvas 六热点 / revision 重绘 | `flutter test` | **已执行，2/2 通过** |
| R01–R09 | 衣橱 CRUD、收藏幂等、缺失恢复、状态同步、快照不可变 | `flutter test` | **已执行，9/9 通过** |
| E01–E06 | 空衣橱、衣橱内单品、缺鞋部分方案、真实理由、非拥有排除、连衣裙互斥 | `flutter test` | **已执行，6/6 通过** |
| W03–W10 | 首页完整闭环、锁定确认、缺失恢复、320px、缩略图、空衣橱导入、大字体、隐私页删除 | `flutter test` | **已执行，8/8 通过** |
| P01–P11 | JSON 往返、重启恢复、清空不重置、损坏回退、存储失败、收藏顺序、草稿隔离、SharedPreferences 读写、存储删除、删除本机数据、导出 | `flutter test` | **已执行，11/11 通过** |
| WEB01–WEB11 | 首页/欢迎/衣橱/收藏/我的/320/430/语义/选衣弹层/JS/控制台 | Flutter Web + Edge | **已执行，11/11 通过** |
| STORE-01 | 衣橱 / 收藏 / 偏好跨启动恢复 | 本地持久化（单元 + mock） | **已执行**；真机进程重启未验证 |
| STORE-02 | 本地数据版本迁移 / 加密 / 多账号隔离 | 真机 + 安全评审 | **未实施** |
| DATA-01 | 删除本机衣橱 / 收藏 / 偏好并持久化空快照 | `flutter test` + Widget | **已执行**（P09/P10/W10） |
| DATA-02 | 导出本机数据 JSON | `flutter test` | **已执行**（P11）；真机剪贴板未验证 |
| PERF-01 | 人物换装响应 p50 / p95 | Android/iOS 真机 | **未执行**（无设备） |
| VIS-01 | 320/390/430px 真机布局与安全区 | 真机 | **部分**：Web 视口与 Widget 通过；真机未执行 |
| A11Y-01 | 1.3 倍大字体 / 屏幕阅读器 | Widget / 真机 | **部分**：Widget 大字体通过；TalkBack/VoiceOver 未测 |
| IMG-01 | 实际服装模板贴合效果 | 真实服装样本 | **未执行**（无素材与样本） |
| API-01 | 用户隔离 / 服务端持久化 | 后端集成测试 | **未实施** |
| AI-01 | 服装属性识别准确率 | 标注数据集 | **未实施** |

## 运行命令

```bash
# Node 契约（项目根目录）
node --test tools/verify_state_contract.mjs

# HTML 原型（需要 Playwright + 本机 Chrome/Chromium）
python tools/verify_browser.py

# Flutter 静态分析与测试
cd flutter_mvp
flutter pub get
flutter analyze
flutter test

# Flutter Web 真实渲染截图
flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn
cd ..
python tools/verify_flutter_web.py
```

**通过标准：** `flutter analyze` 无 issue；全部 Flutter 测试（当前 51 项）无失败；Web 检查无失败；真机流程需另行执行后才能标记完成。**当前真机相关项仍未完成。**
