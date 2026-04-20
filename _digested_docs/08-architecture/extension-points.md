# 扩展点（想改/加东西时看哪里）

## 场景 1：加一个新的 coding agent

比如「想支持新的 AI IDE『XYZ』」。三步：

### 1. 注册到 `AI_TOOLS` 数组

[src/core/config.ts](../../src/core/config.ts) 第 21–50 行，加一条：

```ts
{
  name: 'XYZ',
  value: 'xyz',
  available: true,
  successLabel: 'XYZ',
  skillsDir: '.xyz',
  detectionPaths: ['.xyz/config.json'],   // 可选，覆盖 skillsDir 的自动检测
}
```

### 2. 写一个 command adapter

[src/core/command-generation/adapters/xyz.ts](../../src/core/command-generation/adapters/)，实现 `CommandAdapter` 接口（见 [types.ts](../../src/core/command-generation/types.ts)）：

```ts
import type { CommandAdapter } from '../types.js';

export const xyzAdapter: CommandAdapter = {
  toolId: 'xyz',
  commandDir: '.xyz/commands',
  commandFile: (id) => `opsx-${id}.md`,
  renderCommand: (content) => content,   // 纯 markdown
};
```

### 3. 在 registry 注册

[src/core/command-generation/adapters/index.ts](../../src/core/command-generation/adapters/) 或 [registry.ts](../../src/core/command-generation/registry.ts) 里 import 并加入 adapter 列表。

**如果不想要 command，只要 skill**（像 Trae / ForgeCode）：跳过步骤 2、3，只在 `AI_TOOLS` 里注册 `skillsDir`。

### 4. 更新文档
- [docs/supported-tools.md](../../docs/supported-tools.md) 加一行
- 本消化笔记的 [04-supported-tools/README.md](../04-supported-tools/README.md) 加一行

---

## 场景 2：加一个新的 workflow（`/opsx:<new-id>`）

### 1. 写模板

[src/core/templates/workflows/<new-id>.ts](../../src/core/templates/workflows/)，导出两个函数：

```ts
export function get<NewId>SkillTemplate(): SkillTemplate { ... }
export function getOpsx<NewId>CommandTemplate(): CommandTemplate { ... }
```

参考已有的 [propose.ts](../../src/core/templates/workflows/propose.ts) 和 [apply-change.ts](../../src/core/templates/workflows/apply-change.ts)。

### 2. 注册到 `ALL_WORKFLOWS`

[src/core/profiles.ts](../../src/core/profiles.ts) 数组里加 id：

```ts
export const ALL_WORKFLOWS = [
  'propose', 'explore', /* ... */ 'onboard',
  'new-id',           // 新的
] as const;
```

如果想进 `core` 默认集，也加到 `CORE_WORKFLOWS`。

### 3. 注册到 skill 和 command generation

[src/core/shared/skill-generation.ts](../../src/core/shared/skill-generation.ts)：
- `getSkillTemplates` 的 all 数组里加一条（行 50–69 风格）
- `getCommandTemplates` 的 all 数组里加一条（行 83–95 风格）

### 4. 如果新 workflow 要查 artifact graph

看 [src/commands/workflow/](../../src/commands/workflow/) 里的 `instructions.ts` 和 `status.ts`，把新的 artifact 查询逻辑加进去。

---

## 场景 3：加一个新的 schema

直接用 CLI：

```bash
openspec schema init my-schema
# 或
openspec schema fork spec-driven my-schema
```

自定义 schema 不需要改源码（存放在 `openspec/schemas/<name>/` 或 `~/.local/share/openspec/schemas/<name>/`）。

**如果想让新 schema 成为内置（和 `spec-driven` 并列）**：
1. 在 [schemas/](../../schemas/) 加一个目录
2. 在 [src/core/artifact-graph/resolver.ts](../../src/core/artifact-graph/resolver.ts) 里确认包级查找能找到它
3. 改 default schema 时考虑 [src/core/artifact-graph/](../../src/core/artifact-graph/)

---

## 场景 4：改 artifact state 判定逻辑

比如「我想让 artifact 用 Git 提交状态而不是文件存在来判 done」。

→ 改 [src/core/artifact-graph/state.ts](../../src/core/artifact-graph/state.ts)。

---

## 场景 5：给 delta spec 加一种新 section（比如 `## DEPRECATED Requirements`）

→ 改 [src/core/parsers/](../../src/core/parsers/) 里的 delta parser + [src/core/specs-apply.ts](../../src/core/specs-apply.ts) 的 merge 逻辑。

---

## 场景 6：改全局 config 字段

→ 改 [src/core/config-schema.ts](../../src/core/config-schema.ts)（zod schema）+ [src/core/global-config.ts](../../src/core/global-config.ts)（读写）+ [src/commands/config.ts](../../src/commands/config.ts)（CLI）。

---

## 场景 7：改 archive 的行为

→ [src/core/archive.ts](../../src/core/archive.ts)（主流程）+ [src/core/specs-apply.ts](../../src/core/specs-apply.ts)（spec 合并）。

---

## 扩展心智地图

```
加新 coding agent   → config.ts + command-generation/adapters/
加新 workflow 命令  → templates/workflows/ + profiles.ts + shared/skill-generation.ts
加新 schema         → CLI 就够了，或加到 schemas/
改状态判定          → artifact-graph/state.ts
改 delta 格式       → parsers/ + specs-apply.ts
改 archive 逻辑     → archive.ts
改全局 config       → config-schema.ts + global-config.ts + commands/config.ts
改项目 config       → project-config.ts
```

**原则**：OpenSpec 尽量把「数据（schema、模板、配置）」和「逻辑（引擎）」分开。大部分定制只改数据不改逻辑——这就是 OPSX 的核心价值。
