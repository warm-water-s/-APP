# ADR-003 — 应用级状态容器与本地 Repository 边界

**状态：** 采用（V1.0，含本地持久化）  
**日期：** 2026-10-18（同日更新持久化实现）

## 背景

技术验证阶段只有 `CurrentOutfitController` 和演示页面。进入 Milestone 1 后，衣橱列表、
服装编辑、收藏列表和四个 Tab 都需要读写同一份数据；如果每个页面各自保存一份服装或收藏，
就会出现人物、卡片、收藏互相不一致的问题。与此同时，后端、鉴权和持久化尚未实现。

## 决策

1. 新增 `AppState` 作为应用级组合根：
   - 持有 `WardrobeRepository`、`SavedOutfitsRepository` 和唯一的 `CurrentOutfitController`；
   - 监听衣橱变化并调用 `controller.replaceCloset()`，让被删除的衣服同步从当前穿搭移除；
   - 页面只通过 `AppState` 读写，不创建第二份 `CurrentOutfit`。
2. 衣橱和收藏使用**内存 Repository**（`ChangeNotifier`）：
   - 衣橱支持增删改查、类别 / 关键字过滤；
   - 收藏按“风格 + 各槽位服装 ID”指纹幂等写入，重复保存不产生重复记录；
   - 收藏只保存服装 ID，不复制服装数据；恢复时由控制器逐项校验，缺失即空槽。
3. 衣橱、收藏、偏好通过 `OutfitStorage` 自动保存到本机（`shared_preferences` + versioned JSON）：
   - 写入 120ms 防抖；保存失败不阻断 UI，记录 `lastPersistenceError`；
   - 当前穿搭草稿**不持久化**，仍随进程结束清空；
   - 数据损坏或版本不兼容时回退到演示数据。
4. 所有界面明确标注“演示数据 / 保存在本机”，不得当作云端真实衣橱。
5. 后端接入时以 Repository 为替换点：保留 `AppState` 和领域控制器，替换仓库实现即可。

## 影响

- 四个 Tab 共享同一状态，删除服装、保存收藏、恢复收藏可以立即反映到首页人物。
- 为后续 `WardrobeApiRepository`、`SavedOutfitApiRepository` 留出接口位置。
- 在接入真实后端之前，衣橱 / 收藏只在本机单设备生效，**不是账号级同步**；真机跨启动与升级迁移仍需验收。
- 本地数据未加密、未按账号隔离；服务端仍必须独立校验服装所有权，客户端 Repository 不能作为权限依据。
