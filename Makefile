# IR（Intelligent Router）大项目根 Makefile
# =========================================
# 一个文件夹一个子项目：core/（平台服务端）· edge/（机器端程序）。
# 本文件只做编排（委托子项目各自的 Makefile），不含业务逻辑。
#
# 常用：
#   make build        全部子项目构建
#   make test         全部子项目测试
#   make core-start   启动平台服务（后台）
#   make health       服务就绪 + 进程状态总览
#   make help         全部目标一览

CORE ?= core
EDGE ?= edge

CORE_BIN := $(CORE)/dist/ir-agent-server
EDGE_BIN := $(EDGE)/dist/ir

.PHONY: help build test lint \
        core-build core-dev core-start core-stop core-restart core-ps \
        core-test core-lint core-release core-health core-logs core-logs-follow \
        edge-build edge-test edge-lint edge-run edge-release \
        build-all test-all health clean

help:
	@echo "IR 大项目编排（core = 平台服务端 · edge = 机器端程序）"
	@echo ""
	@echo "── 全局 ──────────────────────────────"
	@echo "  make build          两个子项目全部构建"
	@echo "  make test           两个子项目全部测试"
	@echo "  make lint           两个子项目静态检查"
	@echo "  make health         服务就绪 + 进程总览"
	@echo ""
	@echo "── Core（平台服务端，127.0.0.1:8080）─"
	@echo "  make core-build     编译（含 hwhkit bootstrap 校验）"
	@echo "  make core-start     后台启动（/tmp/ir-server.pid|log）"
	@echo "  make core-stop      停止"
	@echo "  make core-restart   重启（先重新编译）"
	@echo "  make core-dev       前台运行（开发模式）"
	@echo "  make core-logs      最近日志 / core-logs-follow 实时跟踪"
	@echo "  make core-test      全部测试"
	@echo "  make core-release   精简 release 二进制"
	@echo "  make core-deploy-build  Linux ARM64 交叉编译（部署产物）"
	@echo ""
	@echo "── Edge（机器端程序 ir）───────────────"
	@echo "  make edge-build     编译（dist/ir）"
	@echo "  make edge-run       前台运行（开发模式）"
	@echo "  make edge-test      全部测试"
	@echo "  make edge-release   打包（goreleaser，待接入）"

# ─── 全局 ────────────────────────────────────────────
build: core-build edge-build
	@echo "✓ 全部构建完成"

test: core-test edge-test
	@echo "✓ 全部测试完成"

lint: core-lint edge-lint
	@echo "✓ 全部静态检查完成"

health: core-ps
	@curl -sf -m 3 http://127.0.0.1:8080/health/ready >/dev/null 2>&1 \
	  && echo "✓ Core 就绪 (127.0.0.1:8080/health/ready)" \
	  || echo "✗ Core 未就绪"

clean:
	$(MAKE) -C $(CORE) clean 2>/dev/null || true
	$(MAKE) -C $(EDGE) clean
	@echo "✓ 清理完成"

# ─── Core（委托 core/Makefile）────────────────────────
core-build:
	$(MAKE) -C $(CORE) build
core-dev:
	$(MAKE) -C $(CORE) dev
core-start:
	$(MAKE) -C $(CORE) start
core-stop:
	$(MAKE) -C $(CORE) stop
core-restart:
	$(MAKE) -C $(CORE) restart
core-ps:
	$(MAKE) -C $(CORE) ps
core-test:
	$(MAKE) -C $(CORE) test
core-lint:
	$(MAKE) -C $(CORE) lint
core-release:
	$(MAKE) -C $(CORE) release
core-deploy-build:
	$(MAKE) -C $(CORE) deploy-build
core-logs:
	$(MAKE) -C $(CORE) logs
core-logs-follow:
	$(MAKE) -C $(CORE) logs-follow
core-health:
	$(MAKE) -C $(CORE) health

# ─── Edge（委托 edge/Makefile）────────────────────────
edge-build:
	$(MAKE) -C $(EDGE) build
edge-run:
	$(MAKE) -C $(EDGE) run
edge-test:
	$(MAKE) -C $(EDGE) test
edge-lint:
	$(MAKE) -C $(EDGE) lint
edge-release:
	@echo "待接入 goreleaser（分发形态：brew tap + install.sh）"

build-all: build
test-all: test
