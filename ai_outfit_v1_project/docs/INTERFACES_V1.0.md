# 数据与接口契约 V1.0（草案）

**定位：** 供后续 Flutter、后端与 AI 开发对齐的建议契约，非已部署 API。具体字段和错误码在服务端实现前需再次评审。

## 1. 命名和兼容策略

- REST 路径以 `/v1/` 开头；JSON 字段使用 `snake_case`。
- Flutter 枚举与 JSON 槽位映射：`top`、`outer`、`bottom`、`dress`、`shoes`、`hat`。
- 服装 ID 只能在当前用户鉴权范围内使用。
- 每次响应提供可追踪 `request_id`。写请求可接收 `idempotency_key`。
- 服装图片不应使用永久匿名公网 URL，应返回受保护的资源访问方式。

## 2. Garment 示例

```json
{
  "id": "gar_001",
  "user_id": "current_authenticated_user",
  "name": "米白色基础衬衫",
  "slot": "top",
  "subcategory": "shirt",
  "primary_color": "#F0ECE4",
  "fit": "regular",
  "style_ids": ["minimal", "commute"],
  "seasons": ["spring", "autumn"],
  "source_type": "photo",
  "source_url": null,
  "image_ref": "image_001",
  "avatar_visual": {
    "template_id": "shirt-basic",
    "anchor_preset": "default-person-v1",
    "preview_status": "fallback"
  }
}
```

`user_id` 由服务端从身份确认；不能信任客户端随意声明本人身份。

## 3. 当前穿搭

```json
{
  "style_id": "minimal",
  "garments": {
    "top": "gar_001",
    "outer": null,
    "bottom": "gar_002",
    "dress": null,
    "shoes": "gar_003",
    "hat": null
  },
  "locked_slots": ["top"],
  "revision": 5
}
```

`revision` 是客户端/当前草稿的状态修订号，不等于数据库记录版本；持久化后服务端应另设并发版本号。推荐响应不可修改锁定槽位。

## 4. 推荐请求（建议）

`POST /v1/recommendations/outfits`

```json
{
  "style_id": "minimal",
  "locked_garments": {"top": "gar_001"},
  "current_garments": {
    "top": "gar_001",
    "outer": null,
    "bottom": null,
    "dress": null,
    "shoes": null,
    "hat": null
  },
  "max_results": 3,
  "wardrobe_version": 12
}
```

### 成功响应示例

```json
{
  "request_id": "req_demo",
  "wardrobe_version": 12,
  "items": [
    {
      "id": "rec_001",
      "style_id": "minimal",
      "garments": {
        "top": "gar_001",
        "outer": null,
        "bottom": "gar_002",
        "dress": null,
        "shoes": "gar_003",
        "hat": null
      },
      "reason": "衬衫和深色直筒裤的比例相对协调。",
      "missing_slots": [],
      "is_complete": true
    }
  ]
}
```

后端必须对最终响应中的每个 `garment_id` 再做所有权/有效性校验。若用户衣柜不足，允许返回部分搭配并声明 `missing_slots`，不能为了凑三套而凭空补齐服装。

## 5. 局部替换（建议）

`POST /v1/recommendations/replacements`

```json
{
  "style_id": "minimal",
  "current_garments": {
    "top": "gar_001",
    "outer": null,
    "bottom": "gar_002",
    "dress": null,
    "shoes": "gar_003",
    "hat": null
  },
  "locked_slots": ["top", "shoes"],
  "replace_slot": "bottom"
}
```

返回可替换的 `garment_id` 列表或组合候选。无替代候选时明确返回空列表及原因，当前穿搭不变。

## 6. 导入流程（建议）

`POST /v1/import-jobs/images`：创建图片识别任务。  
`POST /v1/import-jobs/links`：提交来源 URL；有权限时尝试解析。  
`GET /v1/import-jobs/{id}`：查询 `CREATED/UPLOADING/PROCESSING/NEED_CONFIRMATION/COMPLETED/FAILED/CANCELED`。  
`POST /v1/import-jobs/{id}/confirm`：确认、修正属性并创建正式 garment。

如果图片获取失败，任务保留 `source_url` 并进入手动上传兜底。未授权平台数据不得通过非合规爬虫绕过限制。

## 7. 建议统一错误码

| Code | 含义 | 客户端行为 |
|---|---|---|
| `GARMENT_NOT_OWNED` | ID 不属于当前用户 | 不展示候选，记录告警 |
| `GARMENT_NOT_FOUND` | 服装失效或删除 | 当前套装标缺失 |
| `OUTFIT_LOCK_CONFLICT` | 覆盖锁定槽位 | 要求解锁或明确确认 |
| `OUTFIT_SLOT_CONFLICT` | dress 与上下装冲突 | 给出冲突说明 |
| `WARDROBE_INSUFFICIENT` | 缺少必要单品 | 展示部分套装/添加入口 |
| `IMPORT_SOURCE_UNAVAILABLE` | 商品数据无合法来源 | 切换为上传图片 |
| `IMAGE_PROCESSING_FAILED` | 图像识别失败 | 保留原图，人工修正 |
| `RATE_LIMITED` | 触发服务限制 | 显示重试指导 |

## 8. 发布前必须补充的接口任务

身份体系、对象存储上传签名、商品接入权限、结构化图像输出格式、推荐服务的幂等性、分页、并发修订、服务端数据隔离、安全测试和遥测埋点。

## 9. 客户端本地存储（V1.0 已实现，非服务端契约）

`shared_preferences` key：`ai_outfit_v1_state`，值为 UTF-8 JSON：

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

约束：

- `version` 不匹配或 JSON 损坏时，客户端回退到演示衣橱；**升级迁移尚未实现**。
- 当前穿搭草稿、导入中的草稿、真实图片均不在该快照内。
- “删除本机数据”先删除该 key，再写入一个衣橱/收藏为空的同版本快照，确保重启不重新填充演示数据。
- “导出 JSON”只读取该快照并复制到剪贴板；**不提供导入恢复**，避免把旧数据误当当前状态。
- 本地快照不是账号数据，不能作为服务端权限或数据隔离的依据；后端实现后需以其数据库为准。
- 该结构变更时，必须同步更新 `docs/ARCHITECTURE_V1.0.md` 与持久化测试 P01–P08。
