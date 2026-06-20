# 问题

`openspec/specs/` 里的 main specs 号称是 source of truth、反映项目现状。但用着用着就发现它和真实代码对不上了——要么 spec 里还在说"有这个功能"，代码里早删了；要么代码里新上了一块能力，specs 里只字未提。这种失真会直接坑 coding agent：它把 specs 当事实，结果基于过时或残缺的前提去 propose change。

问题就三个，都是平时最常碰到的：

1. **平时该怎么养成习惯**，别让它一开始就对不上？
2. **怎么"感觉"到一个 main spec 需要修了**——出现什么信号？
3. **真要修的时候**，最常见的做法是什么？

不需要面面俱到，我自己平时照着做的那几条就够。

# 背景

`_digested/specs_truth/` 已经把这件事挖到底了（机理、六类噪声、原语、决策矩阵），但它偏工程手册、偏全。这里要的是一个**通俗、平时视角**的对照版：

- [`../../_digested/specs_truth/01-机理-主specs如何被delta构造.md`](../../_digested/specs_truth/01-机理-主specs如何被delta构造.md) —— 主 specs 是 delta 经 `archive` 累加出来的，requirement 没 ID、身份是标题文本；**capability 身份是目录名**（两层"以名字为身份"）。这是"为什么会失真"的根。
- [`../../_digested/specs_truth/02-漂移与噪声-为什么主specs会失真.md`](../../_digested/specs_truth/02-漂移与噪声-为什么主specs会失真.md) —— 失真的三道缺口和六类噪声信号。
- [`../../_digested/specs_truth/03-手段清单-到底有多少种修法.md`](../../_digested/specs_truth/03-手段清单-到底有多少种修法.md) —— 修法的真实结构是几种"原语"（这篇只挑最常见的几招）。
- [`../../_digested/specs_truth/04-问题到方法-决策矩阵与排错.md`](../../_digested/specs_truth/04-问题到方法-决策矩阵与排错.md) —— 看到 `archive ... not found` 怎么排错。
- [`../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md`](../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md) —— handbook 里讲清"capability 目录名=身份、specs 为什么会漂、怎么守"的一章（用户向，比 specs_truth 通俗）。

边界：本篇只回答"平时的习惯 / 怎么发现 / 最常见的修法"，**不重复** `specs_truth/` 的全量分类，也**不和** [`../archive-ready-to-archived/question.md`](../archive-ready-to-archived/question.md)（讲 archive 那一刻 delta 怎么并进 specs）混为一谈——那是"一次性合并"，本篇讲的是"长期的 specs↔代码漂移"。
