# 技术架构 V1.0

> 参考：[PRD](PRD_V1.0.md) · [UI/UX](UI_UX_V1.0.md) · [验证报告](TECH_VALIDATION_REPORT.md)。  
> **实现更新：** 2026-10-18 v0.3.1。本文同时描述正式 APP 的拟定架构与 `flutter_mvp/` 当前已实现的边界。

## 1. V1.0 系统分层

```text
┌──────────────────────────────────────────────┐
│ Mobile APP · Flutter（已实现本地演示版）       │
│ UI: AppShell / AvatarCanvas / Picker / Cards │
│ APP: AppState（组合根）                       │
│ STATE: CurrentOutfitController               │
│ REPO: WardrobeRepository / SavedOutfitsRepo   │
│       （内存实现，后端替换点）                 │
└──────────────────────┬───────────────────────┘
                       │ 尚未实现：HTTPS JSON API + 图片上传
┌──────────────────────▼───────────────────────┐
│ Backend · FastAPI（建议方案，未实施）          │
│ Auth / Garments / ImportJobs / Outfits        │
│ Rule Recommendation + Async AI Adapter       │
└────────────┬─────────────────┬───────────────┘
             │                 │
      PostgreSQL / OSS      AI 模型 / 任务队列
```

第一版**不采用复杂微服务**；建议后端为模块化单体，图片识别异步处理。当前仓库只实现移动端本地演示层。

## 2. 领域层与界面层责任边界

| 层 | 文件 | 功能 | 当前状态 |
|---|---|---|---|
| 领域实体 | `flutter_mvp/lib/domain/garment.dart` | 服装、槽位、来源、季节等 | 已实现 |
| 不可变状态 | `.../outfit_state.dart` | 当前套装快照、完整性、锁定 | 已实现 |
| 业务控制器 | `.../current_outfit_controller.dart` | 选择、互斥、校验、原子提交 | 已实现，51 项测试覆盖 |
| 收藏实体 | `.../saved_outfit.dart` | 收藏快照、指纹、缺失槽位 | 已实现 |
| 推荐协议 | `.../outfit_recommendation.dart` | 候选、理由、缺失类别 | 已实现 |
| 演示数据 | `flutter_mvp/lib/data/demo_catalog.dart` | 15 件本地演示服装 | 已实现 |
| 演示规则引擎 | `.../demo_recommendation_engine.dart` | 确定性候选与排序 | 已实现，**非 AI** |
| 衣橱仓库 | `.../wardrobe_repository.dart` | 增删改查、筛选、同步失效单品 | 已实现（内存 + 持久化） |
| 收藏仓库 | `.../saved_outfits_repository.dart` | 幂等保存、删除 | 已实现（内存 + 持久化） |
| 本地持久化 | `.../outfit_storage.dart` | versioned JSON、`shared_preferences`、测试用内存实现 | 已实现，P01–P08 |
| 应用组合根 | `.../app_state.dart` | 衣橱 + 收藏 + 当前穿搭 + 偏好 + 自动保存 | 已实现 |
| 2D 人物 | `flutter_mvp/lib/ui/avatar_canvas.dart` | 分层矢量绘制 + 六热点 | 已实现，Widget/Web 验证 |
| 页面 | `flutter_mvp/lib/ui/pages/*` | 首页、衣橱、穿搭、我的、导入、编辑等 | 已实现主要页面 |
| 后端 / AI | 无 | 鉴权、持久化、AI 抠图/识别 | **未实现** |

## 3. CurrentOutfit 状态契约

```json
{
  "style_id": "minimal",
  "garments": {
    "top": "t1",
    "outer": null,
    "bottom": "b1",
    "dress": null,
    "shoes": "s1",
    "hat": null
  },
  "locked_slots": ["top"],
  "revision": 3
}
```

**核心不变量：**

1. 六个槽位始终存在。
2. `dress` 不能与 `top`、`bottom` 同时选中。
3. 锁定槽位必须有服装。
4. 每件候选服装在用户衣柜中存在、未删除、类别与槽位一致。
5. 失败更新不会修改状态或 revision。
6. 每次成功操作产生新 `CurrentOutfit` 快照，并通知所有 UI 观察者。
7. 删除或恢复时不静默补齐缺失的衣服。
8. `styleId` 改变不会自动删除当前手动选中的服装。

`CurrentOutfitController` 是 UI 单一事实来源（Single Source of Truth）；它不替代服务端权限校验。

## 4. 状态事件与业务约束

| 事件 | 参数 | 必须满足 |
|---|---|---|
| `selectGarment` | slot、garmentId、replaceLocked、clearConflictingLocks、lockSelected | 类别/所有权合法；默认锁定；覆盖锁定需显式确认 |
| `toggleLock` | slot | 只能锁定非空槽位 |
| `clearSlot` | slot、force | 锁定槽位不能无确认直接清除 |
| `setStyle` | styleId | 不改变已选衣物 |
| `applyRecommendation` | recommendation | 原子校验每件服装和锁定约束 |
| `restoreSaved` | saved | 缺失衣物以空槽恢复，不沿用旧锁定 |
| `replaceCloset` | garments | 从当前状态移除不存在的单品 |
| `clearAll` | 无 | 清空当前穿搭与锁定 |

手动覆盖已锁定的实现：UI 先显示确认对话框，确认后调用 `replaceLocked: true`；涉及连衣裙互斥时同时传 `clearConflictingLocks: true`，否则控制器拒绝修改。

## 5. AvatarCanvas 分层逻辑

Canvas 内采用逻辑画板 **280 × 480**，等比缩放到容器。绘制顺序：

1. 舞台阴影、人物腿部与手臂。
2. 头发、脸部等基础人物。
3. 下装或连衣裙。
4. 上衣。
5. 外套分片（左右领口和衣身）。
6. 鞋子。
7. 帽子。
8. 交互热点（独立 Flutter Widget，叠放在 Canvas 上方）。

人物热点使用 `AppPill` 小胶囊（图标 + 中文标签），对应 `top/outer/bottom/dress/shoes/hat` 六个入口；热点是独立控件，不依赖像素透明区域，便于无障碍与窄屏点击。

`AvatarCanvas` 只接收 `CurrentOutfit` 和只读 closet，不修改业务状态。`showHotspots: false` 用于收藏缩略图，避免小尺寸溢出。

## 6. 数据流

```text
用户点击上衣热点
→ AvatarCanvas.onSlotTap(top)
→ HomePage 打开 WardrobePickerSheet
→ 用户选择 t1
→ CurrentOutfitController.selectGarment(top, t1)
→ 校验类别 / 锁定 / 连衣裙互斥
→ 创建 revision+1 的不可变 CurrentOutfit
→ notifyListeners()
→ AvatarCanvas 重绘 + 槽位卡 + 推荐区同步刷新
→ 保存时 AppState.saveCurrentOutfit() 取快照写入 SavedOutfitsRepository
→ AppState 监听衣橱 / 收藏变化，120ms 防抖后写入本地 JSON
```

推荐采用同样数据流，区别是 `applyRecommendation()` **一次校验全部候选、一次提交**，避免逐个槽位更新产生中间态。

删除服装时：`WardrobeRepository` 通知 → `AppState` 调 `controller.replaceCloset()` → 无效单品与锁定被移除 → 所有页面刷新 → 本地快照更新。收藏不复制服装数据，因此恢复时缺失项显示为空槽。

## 7. 页面与导航（当前实现）

| 页面 | 文件 | 状态 |
|---|---|---|
| AppShell 四 Tab | `app.dart` | 首页 / 衣橱 / 穿搭 / 我的 |
| 欢迎 / 演示登录 | `pages/welcome_page.dart`、`login_page.dart` | 未接真实账号 |
| UI-03 首页换装 | `pages/home_page.dart` | 完整闭环（本地） |
| UI-04 选衣弹层 | `widgets/wardrobe_picker_sheet.dart` | 类别、空态、移除、添加 |
| UI-05 推荐方案 | `home_page.dart` 内部组件 | 1–3 套、换一套、保存、缺失提示 |
| UI-06 衣橱 | `pages/wardrobe_page.dart` | 搜索、筛选、双列卡片 |
| UI-07~10 导入 / 编辑 | `pages/import_method_page.dart`、`garment_editor_page.dart` | 演示流程，无真实图片/AI |
| UI-11 服装详情 | `pages/garment_detail_page.dart` | 编辑、删除、穿它去搭配 |
| UI-12/13 收藏 | `pages/outfits_page.dart`、`outfit_detail_page.dart` | 列表、详情、缺失、恢复 |
| UI-14/15/16 我的 | `pages/profile_page.dart` 等 | 统计、偏好、隐私 |

## 8. 本地持久化与演示边界

### 8.1 存储内容

衣橱、收藏、风格偏好、是否看过欢迎页保存在本机；**当前穿搭草稿不持久化**，重启后为空。首次启动时写入 15 件演示服装；`has_wardrobe=true` 后即使用户清空衣柜，也不会再次填充演示数据。

```json
{
  "version": 1,
  "has_wardrobe": true,
  "wardrobe": [
    {
      "id": "t1",
      "name": "米白色基础衬衫",
      "slot": "top",
      "subcategory": "衬衫",
      "color_hex": "#F0ECE4",
      "style_ids": ["minimal"],
      "seasons": [],
      "owned": true,
      "source_type": "demo",
      "source_url": null,
      "image_ref": null,
      "fit": null,
      "pattern": null,
      "note": null
    }
  ],
  "saved_outfits": [
    {
      "id": "saved-1",
      "name": "通勤一套",
      "style_id": "minimal",
      "garments": {"top": "t1", "outer": null, "bottom": "b1", "dress": null, "shoes": "s1", "hat": null},
      "created_at": "2026-10-18T10:30:00.000"
    }
  ],
  "preferred_styles": ["minimal"],
  "welcome_seen": true
}
```

### 8.2 实现约束

- `OutfitStorage` 是抽象接口：`SharedPreferencesOutfitStorage` 用于真机/Web，`InMemoryOutfitStorage` 用于测试和截图。
- 写入 120ms 防抖；存储失败不阻断 UI，错误保存在 `AppState.lastPersistenceError`，下次成功写入时清除。
- 版本不匹配或 JSON 损坏时回退为 `null`，重新使用演示数据；**升级迁移尚未实现**。
- 本地数据未加密、未按账号隔离；接入账号体系前不能用于多用户设备。

### 8.3 数据删除与导出

- 隐私页“导出 JSON”调用 `AppState.exportData()`，把当前快照复制到剪贴板；不包含当前穿搭草稿。
- “删除本机数据”调用 `AppState.clearPersonalData()`：
  1. 清空当前穿搭、衣橱、收藏、偏好；
  2. 删除本地存储 key；
  3. 写入一个 `has_wardrobe: true` 的空快照，避免下次启动重新填充演示衣橱；
  4. 欢迎页状态保持不变。
- 删除操作有二次确认；存储失败会记录 `lastPersistenceError` 并在 UI 提示。

### 8.4 边界

- 页面明确标注“演示数据 / 保存在本机”；不得把演示衣柜当真实用户衣柜。
- `WardrobeRepository` / `SavedOutfitsRepository` 是后续 API 接入的替换点；保留 `AppState` 与控制器即可切换实现（ADR-003）。
- 真实图片、AI 识别、裁剪上传、淘宝授权、后端鉴权均未实现；`INTERFACES_V1.0.md` 只是契约草案。

## 9. 重要集成风险

- 用户上传图片不一定贴合人物：当前采用标准轮廓 + 主色，真实商品图只作为卡片展示。
- 2D 材质与锚点规范尚未制作；`assets/README.md` 记录了后续 `GarmentVisualAsset` 约定。
- 推荐为确定性演示算法，不是经过训练/评估的模型。
- `ChangeNotifier` 足以验证 MVP；将来可封装 Repository 或 Riverpod/BLoC，但不能同时存在两份不一致的 CurrentOutfit。
- Flutter Web 真实渲染已验证，但机型性能、内存、安全区与无障碍仍需真机实测。
- 本地持久化已实现，但真机跨启动、应用升级迁移、加密与多账号隔离未验证。
- 数据删除写入空快照；真机剪贴板导出与删除流程未验证。
- 本地存储是“单用户单设备”模型，不能替代服务端鉴权与数据隔离。

## 10. 建议下一步开发次序

1. 安装 Android SDK/JDK，补真机编译与运行验收。
2. 在真机验证本地数据跨启动恢复、剪贴板导出与删除流程，补 schema 迁移。
3. 接入图片选择、裁剪与上传，保留手动确认兜底。
4. 制定 `GarmentVisualAsset` JSON 与分层素材，逐步替换 CustomPainter 示意。
5. 接入后端鉴权与服装 CRUD，验证数据隔离；再处理真实 AI 识别与推荐。
