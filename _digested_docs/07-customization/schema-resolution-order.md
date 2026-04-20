# Schema 解析优先级

OpenSpec 需要一个 schema 时，按优先级从高到低查。

## 优先级 1：决定用哪个 schema 名字

当用户执行命令（比如 `/opsx:new`），选哪个 schema 名字按下面顺序找（高到低）：

```
1. CLI flag            --schema <name>
2. Change 元数据       openspec/changes/<name>/.openspec.yaml 的 schema 字段
3. 项目 config         openspec/config.yaml 的 schema 字段
4. 默认                spec-driven
```

**例子**：

```bash
# 强制用 rapid（第 1 级）
openspec new change my-feature --schema rapid

# 没 flag 就查 change 自己的 .openspec.yaml（第 2 级）
openspec continue my-feature
# → 读 openspec/changes/my-feature/.openspec.yaml

# 都没的话，读项目 config（第 3 级）
# → 读 openspec/config.yaml 的 schema:
```

## 优先级 2：决定 schema 名字从哪里加载

确定了 schema 名字后（比如 `my-workflow`），按下面顺序找实际文件：

```
1. 项目            openspec/schemas/my-workflow/
2. 用户            ~/.local/share/openspec/schemas/my-workflow/
3. 包内置          <npm-install>/schemas/my-workflow/
```

可以用 `openspec schema which` 看：

```bash
openspec schema which spec-driven
# 输出：
# spec-driven resolves from: package
#   Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven

openspec schema which my-workflow
# 输出：
# my-workflow resolves from: project
#   Source: /path/to/project/openspec/schemas/my-workflow

openspec schema which --all
# 列出所有 schema 和各自来源
```

## 为什么是这个顺序

- **项目** 最高——同名 schema 可以覆盖用户级 / 包内置，让团队对仓库内的工作流有完全控制
- **用户** 其次——跨项目共享（比如个人偏好的 schema）
- **包** 最后——给一个保底的 `spec-driven`

## 实战建议

| 场景 | 推荐位置 |
|------|---------|
| 团队共享、需要版本控制 | 项目级（`openspec/schemas/`） |
| 个人跨项目复用 | 用户级（`~/.local/share/openspec/schemas/`） |
| 公共贡献回 npm | 发 PR 到 [schemas/](../../schemas/) 目录 |

## 和项目 config 的配合

典型组合：

```yaml
# openspec/config.yaml
schema: my-workflow      # 项目默认用 my-workflow
```

```
openspec/schemas/my-workflow/   # 对应的 schema 文件
├── schema.yaml
└── templates/
```

之后所有不带 `--schema` flag 的命令都会用 `my-workflow`（来自**项目 openspec/**下的定义）。
