SUBDIRS = app example endpoint file iam plugin user
define make-api
	@for dir in $(SUBDIRS); do \
		$(MAKE) -f ./api.mk PROTO_DIR="$$dir" OUTPUT_DIR="../api/$$dir/v1" $(1); \
	done
endef
go:
	$(call make-api,go)

ts:
	$(call make-api,ts)

py:
	$(call make-api,py)
all: go ts py
	@echo "All done"
	@echo "Go to the api directory and run make all"
.PHONY: go ts py all