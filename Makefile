# ROS2 Security POC - 便捷指令封裝
# 用法: make <target>；make help 列出全部
.DEFAULT_GOAL := help
.PHONY: help deploy start start-secure stop attack verify harden firewall teardown clean all

help:  ## 顯示可用指令
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

deploy:  ## 建置並啟動隔離環境
	bash scripts/deploy.sh

start:  ## 啟動靶場節點（無安全）
	bash scripts/start_nodes.sh

start-secure:  ## 啟動靶場節點（SROS2 安全模式）
	bash scripts/start_nodes.sh --secure

stop:  ## 停止所有靶場節點
	bash scripts/stop_nodes.sh

attack:  ## 執行全部攻擊測試（2.1-2.7）
	bash scripts/run_attacks.sh --label baseline

harden:  ## 建立 SROS2 keystore 並以安全模式重啟
	docker exec sectest-victim bash -lc 'bash /work/hardening/setup_sros2.sh'
	bash scripts/start_nodes.sh --secure

firewall:  ## 套用網路層限流防火牆
	docker exec sectest-victim bash -lc 'bash /work/hardening/firewall.sh apply'

verify:  ## 驗證加密 + 存取控制 + 偵測
	bash scripts/verify.sh --detect

teardown:  ## 銷毀容器環境
	bash scripts/teardown.sh

clean:  ## 銷毀環境並清除 keystore
	bash scripts/teardown.sh --volumes

all:  ## 完整流程（部署→攻擊→加固→驗證）
	bash scripts/run_all.sh
