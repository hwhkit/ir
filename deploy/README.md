# IR —— 本机 Docker 完整部署套

一套三容器闭环：`ir-db`（PostgreSQL 16）→ `ir-core`（平台服务端）→ `ir-edge`（bash 版连接器 + 演示管线）。
与开发环境完全隔离（独立库 `ir`、端口 18080、容器名 ir-*）。

## 快速开始

```bash
cd <IR 大项目根>
docker compose -f deploy/docker-compose.yml up -d --build
# 首次构建约 3-5 分钟（core 镜像拉 golang/alpine + go build）

./deploy/demo-task.sh "第一次演示任务"     # 注入任务 → Edge 数秒内认领执行
docker compose -f deploy/docker-compose.yml logs -f edge
docker exec ir-db psql -U ir -d ir -c "SELECT status, result_json FROM agent_runs"
```

| 服务 | 地址 / 状态 |
|---|---|
| Central Console | http://127.0.0.1:18080/admin（admin / ir-demo-admin） |
| agent-api | http://127.0.0.1:18080/agent-api/v1 |
| health | http://127.0.0.1:18080/health/ready |
| Node Console | 待 Edge daemon 内核落地后接入（127.0.0.1:7800） |

## 结构

- `core/Dockerfile`：多阶段构建（golang→alpine）。依赖经 GOPROXY 拉取发布版
  hwhkit-go 子模块，无本地源码树要求。运行镜像 alpine + curl/jq（healthcheck 用）。
- `edge/Dockerfile`：alpine + bash/jq/curl/python3 + scripts/agent-pool 全套 + 演示管线。
  Edge 是纯出站连接，无入站端口。
- `init.py`（core-init 一次性容器）：等 Core 健康 → admin 登录（cookiejar）→
  创建 remote_pull 演示智能体 `pool-demo`（密钥预置 `demo-master-key-ir001`，
  仅演示用；生产凭据只在签发时展示）。
- `demo-task.sh`：SQL 直插租约队列并同步登记 `agent_runs`（演示用法）。

## 遇到的真实问题（已修复，fresh 库部署必读）

1. **GOPROXY**：容器内默认 proxy.golang.org 不可达，镜像内设置 `goproxy.cn`。
2. **`PLATFORM__ENABLED=true` 必须显式**（v2 二进制 = 平台本体，遗留占位模式已退役）。
3. **fresh 库迁移顺序 bug**（已修）：`agent_pull_workers` 的 ALTER 曾排在 CREATE 之前，
   老库不暴露、fresh 库首次启动必炸——DDL 顺序已修正。
