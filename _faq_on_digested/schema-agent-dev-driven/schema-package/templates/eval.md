# Eval：`skills/[skill-name].md`

> 对应 skill：[skill 名]
> 可重复执行：是

## 正常路径

### Case 1: [场景名]

- **输入**：`[标准输入内容或文件路径]`
- **期望输出**：
  - [断言 1]：`[判定命令，如 grep 'keyword' output.md]`
  - [断言 2]：`[判定命令]`

## 边界情况

### Case 2: [场景名]

- **输入**：`[残缺/超长/歧义输入]`
- **期望行为**：[降级 / 追问具体字段 / 返回错误但不崩溃]
- **断言**：`[判定命令]`

## 拒绝场景

### Case 3: [越界请求]

- **输入**：`[越界输入内容]`
- **期望拒绝理由**：[匹配 persona.md 中定义的拒绝话术关键词]
- **断言**：`grep -i '[关键词]' [输出文件]`

---

> **判定命令汇总**（一次性执行）：
> ```bash
> # Case 1
> grep '…' output.md
>
> # Case 2
> test -f path/to/file && grep '…' path/to/file
>
> # Case 3
> grep -i '拒绝' output.md || grep -i 'cannot' output.md
> ```
