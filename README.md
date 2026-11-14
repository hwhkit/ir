# IR（Intelligent Router）大项目根目录

一个文件夹对应一个子项目：

| 目录 | 子项目 | 说明 |
|---|---|---|
| `core/` | **IR Core** | 平台服务端（git 仓库，module ir-agent-server） |
| `edge/` | **IR Edge** | 机器端程序 `ir`（git 仓库，module ir-edge） |
| `archive/` | 归档 | DeAlan 池脚本（pool-scripts，历史参考） |

两个 git 仓库只通过 IR Link 协议（agent-api/v1）通信，契约见
`core/doc/AGENT-PULL-API.md`。术语体系见 `edge/README.md`；系统架构图（SVG 可视化）见 [doc/architecture.html](doc/architecture.html)（浏览器直接打开）。

依赖：core 通过 GitHub 发布版引用通用库 `hwhkit-go`（tokengen/secrets/retry 等
子模块，tag `*/vX.Y.Z`），无本地 sibling 源码依赖。
