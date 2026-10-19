# AGENTS.md — AI Outfit 项目开发规则

## 1. 项目位置

当前 Git 仓库的实际 APP 项目位于：

`ai_outfit_v1_project/`

所有应用代码、产品文档、测试和资源必须保存在该目录内。

## 2. 开始工作前

每次接手任务，先阅读：

1. `ai_outfit_v1_project/README.md`
2. `ai_outfit_v1_project/docs/AI_HANDOFF.md`
3. `ai_outfit_v1_project/docs/PRD_V1.0.md`
4. `ai_outfit_v1_project/docs/ARCHITECTURE_V1.0.md`
5. 与当前任务相关的 UI/UX、API 和测试文档。

先执行 `git status`，不得覆盖已有未提交修改。

## 3. 开发规则

* 保持 V1.0 的 2D 虚拟换装产品定位。
* 以现有 Flutter 工程为基础持续开发。
* 不重复创建 APP 工程。
* CurrentOutfitController 是当前穿搭状态的统一管理入口。
* AvatarCanvas 负责人物展示，不直接修改业务状态。
* 搭配必须基于当前用户真实拥有的服装。
* 推荐不能覆盖已锁定单品。
* 连衣裙与普通上下装遵守既定互斥规则。
* 真实服务未接入时必须标明 Mock 或 Demo。

## 4. 文件规范

* APP 源码：`ai_outfit_v1_project/flutter_mvp/`
* 后端服务：`ai_outfit_v1_project/backend/`
* 项目文档：`ai_outfit_v1_project/docs/`
* UI 原型：`ai_outfit_v1_project/prototype/`
* 自动化测试：对应模块的 `test/` 或 `tests/`。
* 验证报告：`ai_outfit_v1_project/reports/` 及相关技术文档。

## 5. 测试要求

修改核心业务规则后，必须运行相关单元测试。

修改 UI 组件后，必须进行适用的 Widget 或交互测试。

禁止将未执行的测试标记为通过。

## 6. 文档维护

开发过程中保持代码和文档同步。

每次开发阶段完成后更新：

* `CHANGELOG.md`
* `docs/DEV_TASKS.md`
* 必要时更新 `docs/TECH_VALIDATION_REPORT.md`

修改重要架构决策时增加或更新 ADR。

## 7. Git 规范

* 在现有仓库内完成开发。
* 避免不必要的文件移动或重命名。
* 不覆盖用户未提交的工作。
* 不提交密钥、账号凭证或私人图片。
* 提交前检查测试结果和修改范围。
* 未经用户明确授权，不执行破坏性 Git 操作或远程推送。

## 8. 最终交付要求

每项任务结束时说明：

* 完成的功能。
* 修改的文件。
* 已运行的测试及结果。
* 尚未完成的工作。
* 已知风险。
* 建议的下一步任务。
