# 父目录的Makefile

# 定义变量
PROTOC = protoc
PYTHON = python3
TS_PROTO_PLUGIN = $(shell which protoc-gen-ts_proto)
# 默认目标文件夹和参数
PROTO_DIR ?= .
OUTPUT_DIR ?= ../api/v1
COMMON_OUT_DIR ?= ..
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
		  --ts_proto_opt=Mgoogle/protobuf/field_mask.proto=../../google/protobuf/field_mask \
		  --ts_proto_opt=Mgoogle/protobuf/timestamp.proto=../../google/protobuf/timestamp \
		  --ts_proto_opt=Mgoogle/protobuf/any.proto=../../google/protobuf/any \
		  --ts_proto_opt=Mgoogle/protobuf/descriptor.proto=../../google/protobuf/descriptor \
		  --ts_proto_opt=Mgoogle/protobuf/struct.proto=../../google/protobuf/struct \
		  --ts_proto_opt=Mgoogle/protobuf/empty.proto=../../google/protobuf/empty \
		  --ts_proto_opt=Mgoogle/api/annotations.proto=../../google/api/annotations \
		  --ts_proto_opt=Mgoogle/api/http.proto=../../google/api/http \
		  --ts_proto_opt=Mgoogle/api/httpbody.proto=../../google/api/httpbody \
          --ts_proto_out=$(OUTPUT_DIR)



common:
	@mkdir -p $(OUTPUT_DIR)
.PHONY: make_dir generate go python ts common clean desc all
clean:
	@echo $(COMMON_PROTO_FILES) $(COMMON_FILES) “公共文件”
	@rm -rf $(COMMON_PROTO_FILES)
# 生成所有代码
generate: make_dir go python ts common clean desc all

# 生成 Go 代码
go: $(GO_PROTO_FILES) | common
	$(PROTOC) -I=$(PROTO_DIR) -I=$(COMMON_PROTOS_DIR) -I=$(GOOGLE_PROTOS_DIR) $(GO_ARGS) $?
	protoc-go-inject-tag -input="$(OUTPUT_DIR)/*.pb.go"

ts: $(TS_PROTO_FILES) | common
	$(PROTOC) -I=$(PROTO_DIR) -I=./common $(TS_ARGS) $?

py: $(PY_PROTO_FILES) | common
	$(PYTHON) -m grpc_tools.protoc -I=$(PROTO_DIR) -I=$(GOOGLE_PROTOS_DIR) $(PY_ARGS) $?
	touch $(OUTPUT_DIR)/__init__.py
	echo "#!/usr/bin/env python" > $(OUTPUT_DIR)/__init__.py
	echo "Current path: $(shell pwd)"
	sed -i '/from/!s/import \(.*\) as/from . import \1 as/g' $(OUTPUT_DIR)/$\*.py*
	echo "Parent path: $(PARENT_DIR_NAME)"
	sed -i 's/from begonia import \(.*\) as/from $(PARENT_DIR_NAME).api.begonia.v1 import \1 as/' $(OUTPUT_DIR)/$\*.py*

desc:
	protoc --descriptor_set_out="api.bin" --include_imports --proto_path=./ --proto_path=./common ./*.proto 
all: go ts py desc
	@echo "All done"
	@echo "Go to the api directory and run make all"