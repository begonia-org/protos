# Makefile

# 定义变量
PROTOC = protoc
PYTHON = python3
TS_PROTO_PLUGIN = $(shell which protoc-gen-ts_proto)

# 目标文件夹
PROTO_DIR = ./common/begonia/api/v1
OUTPUT_DIR = ../api/common/v1
PY_PROTO_DIR = ./common

PY_OUTPUT_DIR = ../api/v1
COMMON_FILES = $(wildcard $(PROTO_DIR)/*.proto)
COMMON_PROTO_FILES = $(notdir $(COMMON_FILES))
# 文件列表
GO_PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)
PY_PROTO_FILES = $(wildcard $(PY_PROTO_DIR)/begonia/api/v1/*.proto)
TS_PROTO_FILES = $(wildcard $(PROTO_DIR)/begonia/api/v1/*.proto)
# 通用参数
GO_ARGS = --go_out=$(OUTPUT_DIR) --go_opt=paths=source_relative \
          --go-grpc_out=$(OUTPUT_DIR) --grpc-gateway_out=$(OUTPUT_DIR) \
          --grpc-gateway_opt=paths=source_relative --go-grpc_opt=paths=source_relative
PY_ARGS = -m grpc_tools.protoc -I=$(PY_PROTO_DIR) -I=$(PY_PROTO_DIR) --python_out=$(PY_OUTPUT_DIR) \
          --pyi_out=$(PY_OUTPUT_DIR) --grpc_python_out=$(PY_OUTPUT_DIR) 
TS_ARGS = --plugin="protoc-gen-ts=$(TS_PROTO_PLUGIN)" \
          --ts_proto_opt=esModuleInterop=true --ts_proto_opt=paths=source_relative \
          --ts_proto_opt=snakeToCamel=false --ts_proto_opt=oneof=unions \
          --ts_proto_out=$(OUTPUT_DIR)


make_dir:
	@mkdir -p $(OUTPUT_DIR)
make_py_dir:
	@mkdir -p $(PY_OUTPUT_DIR)/common

.PHONY: make_dir make_py_dir generate go python ts

generate: make_dir make_py_dir go python ts

# 生成 Go 代码
go: make_dir
	$(PROTOC) -I=$(PROTO_DIR) $(GO_ARGS) $(COMMON_PROTO_FILES) 
	protoc-go-inject-tag -input="$(OUTPUT_DIR)/*.pb.go"

# 生成 Python 代码
py: $(PY_PROTO_FILES) | make_py_dir
	touch $(PY_OUTPUT_DIR)/__init__.py
	echo "#!/usr/bin/env python" > $(PY_OUTPUT_DIR)/__init__.py
	$(PYTHON) $(PY_ARGS) $?
	sed -i '/from/!s/import \(.*\) as/from . import \1 as/g' $(PY_OUTPUT_DIR)/*.py*
	mv $(PY_OUTPUT_DIR)/begonia/api/v1/* $(PY_OUTPUT_DIR)
	rm -rf $(PY_OUTPUT_DIR)/common
	rm -rf $(PY_OUTPUT_DIR)/begonia
	

# 生成 TypeScript 代码
ts: $(TS_PROTO_FILES) | make_dir
	$(PROTOC) -I=$(PROTO_DIR) $(TS_ARGS) $?


