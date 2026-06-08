# 问题

`npm install -g @fission-ai/openspec` 之后，终端里就多了一个 `openspec` 命令。直接敲 `openspec` 就能跑。这是怎么做到的？是什么脚本？是什么机制让它变成一个系统级可执行文件的？

# 背景

直觉上这肯定是某个脚本，可能是 Python、Node.js 或者 shell 脚本。需要细节 —— 从 npm install 到命令被执行，完整链路是什么。
