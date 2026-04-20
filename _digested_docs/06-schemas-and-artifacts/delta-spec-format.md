# Delta Spec 格式（brownfield 核心）

## 为什么要 delta

OpenSpec 是为**老代码库**设计的。现实工作的 80% 是改已有系统，只有 20% 是从零建。所以：

- `openspec/specs/` 是「现在系统长什么样」——source of truth
- `openspec/changes/<name>/specs/` 是「这次改动长什么样」——delta

archive 时，delta 合并回 specs，specs 长大一点；下一次 change 基于新的 specs。

## Delta 的四种 section

每个 delta spec 文件（`changes/<name>/specs/<domain>/spec.md`）用 `## XXX Requirements` header 组织：

| Section | 语义 | archive 时的行为 |
|---------|------|-----------------|
| `## ADDED Requirements` | 新增 requirement | 追加到主 spec |
| `## MODIFIED Requirements` | 修改现有 requirement | 替换同名 requirement（必须放**完整**新内容） |
| `## REMOVED Requirements` | 废弃 requirement | 从主 spec 删除；**必须写 Reason 和 Migration** |
| `## RENAMED Requirements` | 只改名字 | 用 `FROM: old name` / `TO: new name` 格式 |

## 完整格式示例

```markdown
# Delta for Auth

## ADDED Requirements

### Requirement: Two-Factor Authentication
The system MUST support TOTP-based two-factor authentication.

#### Scenario: 2FA enrollment
- **WHEN** user enables 2FA in settings
- **THEN** a QR code is displayed for authenticator app setup
- **AND** the user must verify with a code before activation

## MODIFIED Requirements

### Requirement: Session Expiration
The system MUST expire sessions after 15 minutes of inactivity.
(Previously: 30 minutes)

#### Scenario: Idle timeout
- **WHEN** 15 minutes pass without activity
- **THEN** the session is invalidated

## REMOVED Requirements

### Requirement: Remember Me
**Reason**: Replaced by 2FA — security requirement
**Migration**: Users will need to re-authenticate each session.
```

## 写 delta 的硬性规则（来自 schema.yaml 的 instruction）

1. **每个 requirement `### Requirement: <name>`**，后跟描述
2. **用 SHALL / MUST**（避免 should / may）
3. **每个 scenario 用 4 个 `#`**（`#### Scenario: <name>`）——**少一个 `#` 或用 bullet list 都会静默失败**
4. **每个 requirement 必须至少 1 个 scenario**
5. **MODIFIED 必须复制完整 requirement 内容**——部分粘贴会在归档时丢信息
6. **REMOVED 必须写 Reason 和 Migration**

### MODIFIED 的操作步骤

1. 去 `openspec/specs/<capability>/spec.md` 找原 requirement
2. **完整**复制 `### Requirement:` 到所有 scenario 结束的整块
3. 粘到 delta 的 `## MODIFIED Requirements` 下面
4. 编辑为新内容
5. header 文本必须**空白不敏感地匹配**原 requirement 名

### 常见坑

- **用 MODIFIED 写部分内容** → 归档时丢内容。如果只是加新东西，用 ADDED
- **Scenario 用 3 个 `#`** → 不会被 parser 识别，静默丢失
- **要修改一个 capability 但没在 proposal 的 Capabilities 段列出来** → 不会创建 delta spec

## Scenario 的 Given/When/Then 格式

```markdown
#### Scenario: Successful export
- **WHEN** user clicks "Export" button
- **THEN** system downloads a CSV file with all user data
```

也支持 Given/When/Then 三件套（OpenSpec 更推荐 WHEN/THEN 简写）：

```markdown
#### Scenario: Valid credentials
- **GIVEN** a user with valid credentials
- **WHEN** the user submits login form
- **THEN** a JWT token is returned
- **AND** the user is redirected to dashboard
```

## Archive 时的 merge 逻辑

1. ADDED：追加到主 spec 末尾
2. MODIFIED：在主 spec 里找同名 requirement，整块替换
3. REMOVED：从主 spec 删除同名 requirement
4. RENAMED：只改名，不动内容

具体实现在 [src/core/specs-apply.ts](../../src/core/specs-apply.ts) 和 [src/core/parsers/](../../src/core/parsers/)。
