# Init / Update / Drift

## init 的系统职责

`InitCommand.execute()` 做的不是单纯 mkdir，而是一次投递初始化：

1. 校验目标路径。
2. 检测 legacy artifacts。
3. 检测 available tools。
4. 必要时迁移旧安装。
5. 选择工具。
6. 创建 `openspec/` 基础结构。
7. 根据 profile/delivery 生成 skills/commands。
8. 创建或保留 `openspec/config.yaml`。

它同时改变 repo-local OpenSpec 根和工具侧入口文件。

## update 的系统职责

`UpdateCommand.execute()` 是声明式同步器：

1. 确认 `openspec/` 存在。
2. 根据现有工具目录迁移。
3. 读取 global profile/delivery。
4. 处理 legacy cleanup。
5. 检测 configured tools。
6. 比较 version drift 和 profile/delivery drift。
7. 只更新需要同步的工具，或在 `--force` 下全量更新。
8. 删除取消选择的 skill/command 产物。

所以 update 可能删除 OpenSpec 管理的工具侧文件，但不应删除用户业务文件。

## profile sync drift

`src/core/profile-sync-drift.ts` 负责判断工具侧安装状态是否和当前配置一致。

drift 来源包括：

- global profile 从 `core` 改成 `custom`。
- custom workflows 列表变化。
- delivery 从 `both` 改成 `skills` 或 `commands`。
- 某个工具目录里还留有不再选择的 workflow。

这解释了为什么版本没变时也可能需要 update。

## migration

`src/core/migration.ts` 处理旧安装形态向 profile 系统迁移：

- 扫描已安装 workflow artifacts。
- 推断现有 workflow selection。
- 写入或更新 global config。
- 尽量保留用户已经安装的 workflow 集合。

迁移逻辑属于投递层兼容，不是 change/spec 数据迁移。

## legacy cleanup

`src/core/legacy-cleanup.ts` 只清理 OpenSpec 管理的旧投递 artifacts 和 marker，不应该删除用户自己的任意文件。

init/update 都会接触 legacy cleanup，因为旧版入口文件可能影响新 workflow 的发现和触发。

## workspace update 的差异

workspace update 走 `src/core/workspace/skills.ts`：

- 使用同一份 global profile/workflows。
- 只安装 skills。
- 把 applied profile/delivery/workflow ids 写回 `workspace_skills`。
- 用 `hasWorkspaceSkillProfileDrift()` 检查 drift。

这是一条和 repo-local update 相似但状态落点不同的同步链。
