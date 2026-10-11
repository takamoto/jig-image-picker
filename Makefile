.DEFAULT_GOAL := help
.PHONY: help build test format lint install clean

# Use the SwiftPM from Xcode Command Line Tools, not Nix. Building AppKit / QuickLook directly
# against the system SDK is the shortest path, and CLT ends up installed for macOS work anyway.
# Incremental builds are left to SwiftPM (artifacts stay in .build/, which is not in git).
NAME := jig-image-picker
BIN_DIR ?= $(HOME)/.local/bin
SWIFT := /usr/bin/xcrun swift
# swift-format ships with CLT; its settings are in .swift-format
SWIFT_FORMAT := /usr/bin/xcrun swift-format
FORMAT_PATHS := Package.swift Sources Tests

# SwiftPM looks for Testing.framework under the platform path, which CLT lacks (xcrun fails).
# Only then, pass the copy inside CLT directly. With Xcode.app selected it is found, so add nothing
DEV_DIR := $(shell xcode-select -p 2>/dev/null || echo /Library/Developer/CommandLineTools)
TEST_FLAGS := $(if $(shell /usr/bin/xcrun --show-sdk-platform-path 2>/dev/null),,\
  -Xswiftc -F -Xswiftc "$(DEV_DIR)/Library/Developer/Frameworks" \
  -Xswiftc -plugin-path -Xswiftc "$(DEV_DIR)/usr/lib/swift/host/plugins/testing" \
  -Xlinker -rpath -Xlinker "$(DEV_DIR)/Library/Developer/Frameworks" \
  -Xlinker -rpath -Xlinker "$(DEV_DIR)/Library/Developer/usr/lib")

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## Build in release configuration
	$(SWIFT) build -c release

test: ## Run the unit tests (Tests/)
	$(SWIFT) test $(TEST_FLAGS)

format: ## Rewrite the sources in place with swift-format
	$(SWIFT_FORMAT) format --in-place --recursive --parallel $(FORMAT_PATHS)

lint: ## Check the sources with swift-format (fails on any warning)
	$(SWIFT_FORMAT) lint --strict --recursive --parallel $(FORMAT_PATHS)

install: build ## Build and put the binary at $(BIN_DIR)/$(NAME)
	mkdir -p "$(BIN_DIR)"
	cp "$$($(SWIFT) build -c release --show-bin-path)/$(NAME)" "$(BIN_DIR)/$(NAME)"

clean: ## Remove build artifacts (.build/)
	rm -rf .build
