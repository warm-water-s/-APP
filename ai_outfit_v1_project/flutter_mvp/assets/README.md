# assets/ — 人物与服装素材目录

V1.0 当前**没有二进制图片素材**：`AvatarCanvas` 使用 `CustomPainter` 在统一逻辑坐标系
（280 × 480）内绘制标准 2D 人物与服装轮廓，`GarmentSwatch` 使用类别轮廓 + 主颜色绘制
服装卡片占位。这样可以在没有美术资源和真实商品图的情况下，先验证状态、换装与交互闭环。

## 后续接入约定

1. 人物基础层与服装层分开存放，例如：
   - `assets/avatar/base/`：人物身体、头发、面部；
   - `assets/avatar/garments/<slot>/`：按 `top/outer/bottom/dress/shoes/hat` 分目录。
2. 每件服装需要 `GarmentVisualAsset` 描述：`templateId`、`anchorPresetId`、`assetVersion`、
   `baseColor`、可选 `patternId`、`previewStatus`（ready / fallback / failed）。
3. 真实商品图**不能直接拉伸贴到人物身上**；商品图只用于衣柜卡片与详情，人物层使用模板。
4. 新增素材必须标注来源与授权，禁止提交用户私人照片或未授权商品图。
5. 素材缺失时必须回退到当前绘制方案，不能让搭配流程中断。
