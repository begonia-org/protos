SUBDIRS = app example endpoint file iam plugin user sys
define make-api
	@for dir in $(SUBDIRS); do \
		$(MAKE) -f ./api.mk PROTO_DIR="$$dir" OUTPUT_DIR="../api/$$dir/v1" $(1); \
	done
endef
define make-common
	@$(MAKE) -f ./common.mk $(1)
endef
go: desc
	$(call make-common,go)
	$(call make-api,go)

ts:
	$(call make-common,ts)
	$(call make-api,ts)

py:
	$(call make-common,py)
	$(call make-api,py)
desc:
	@mkdir -p ./tmp
	@echo "Go"
	for dir in $(SUBDIRS); do \
		cp ./$$dir/*.proto ./tmp; \
	done
	@cp -r ./common tmp
	protoc --descriptor_set_out="api.bin" --include_imports --proto_path=./tmp --proto_path=./tmp/common ./tmp/*.proto  ./tmp/common/begonia/api/v1/web.proto
	@rm -rf ./tmp
all: go ts py desc
	@echo "All done"
	@echo "Go to the api directory and run make all"
.PHONY: go ts py all desc