# 父目录的Makefile

# 定义变量
PROTOC = protoc
PYTHON = python3
TS_PROTO_PLUGIN = $(shell which protoc-gen-ts_proto)
# 默认目标文件夹和参数
PROTO_DIR ?= .
OUTPUT_DIR ?= ../api/v1
COMMON_PROTOS_DIR ?= ./common
GOOGLE_PROTOS_DIR ?= ./common
PARENT_DIR_NAME ?= $(notdir $(patsubst %/,%,$(dir $(CURDIR))))

# 文件列表
GO_PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)
PY_PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)
TS_PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)
COMMON_FILES = $(wildcard $(COMMON_PROTOS_DIR)/begonia/api/v1/*.proto)
COMMON_PROTO_FILES = $(notdir $(COMMON_FILES))

# 通用参数
GO_ARGS = --go_out=$(OUTPUT_DIR) --go_opt=paths=source_relative \
          --go-grpc_out=$(OUTPUT_DIR) --grpc-gateway_out=$(OUTPUT_DIR) \
          --grpc-gateway_opt=paths=source_relative --go-grpc_opt=paths=source_relative
PY_ARGS = --python_out=$(OUTPUT_DIR) \
          --pyi_out=$(OUTPUT_DIR) --grpc_python_out=$(OUTPUT_DIR) 
TS_ARGS = --plugin="protoc-gen-ts=$(TS_PROTO_PLUGIN)" \
          --ts_proto_opt=esModuleInterop=true --ts_proto_opt=paths=source_relative \
          --ts_proto_opt=snakeToCamel=false --ts_proto_opt=oneof=unions \
          --ts_proto_out=$(OUTPUT_DIR)



common:
	@mkdir -p $(OUTPUT_DIR)
.PHONY: make_dir generate go python ts common clean
clean:
	@echo $(COMMON_PROTO_FILES) $(COMMON_FILES) “公共文件”
	@rm -rf $(COMMON_PROTO_FILES)
# 生成所有代码
generate: make_dir go python ts common clean

# 生成 Go 代码
go: $(GO_PROTO_FILES) | common
	$(PROTOC) -I=$(PROTO_DIR) -I=$(COMMON_PROTOS_DIR) -I=$(GOOGLE_PROTOS_DIR) $(GO_ARGS) $?
	protoc-go-inject-tag -input="$(OUTPUT_DIR)/*.pb.go"

ts: $(TS_PROTO_FILES) $(COMMON_FILES) | common
	$(PROTOC) -I=$(PROTO_DIR) -I=$(COMMON_PROTOS_DIR) -I=$(GOOGLE_PROTOS_DIR) -I=./common $(TS_ARGS) $?

py: $(PY_PROTO_FILES) | common
	$(PYTHON) -m grpc_tools.protoc -I=$(PROTO_DIR) -I=$(GOOGLE_PROTOS_DIR) $(PY_ARGS) $?
	touch $(OUTPUT_DIR)/__init__.py
	echo "#!/usr/bin/env python" > $(OUTPUT_DIR)/__init__.py
	echo "Current path: $(shell pwd)"
	sed -i '/from/!s/import \(.*\) as/from . import \1 as/g' $(OUTPUT_DIR)/$\*.py*
	echo "Parent path: $(PARENT_DIR_NAME)"
	sed -i 's/from common import \(.*\) as/from $(PARENT_DIR_NAME).api.common.v1 import \1 as/' $(OUTPUT_DIR)/$\*.py*
