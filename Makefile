# Makefile – developer convenience targets for SHIPS2-Go

# Detect host OS / arch for local build; override via env if desired.
GOOS   ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GO     ?= go

# Output directories
BIN_DIR := bin
PKG_DIR := ./...

# Version – derive from Git tag if available.
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")

.PHONY: all build clean lint test windows linux release help

all: lint test build

## Build server + client for the host platform
build:
	$(GO) build -trimpath -ldflags "-s -w -X 'main.version=$(VERSION)'" -o $(BIN_DIR)/ships-server ./cmd/server
	$(GO) build -trimpath -ldflags "-s -w -X 'main.version=$(VERSION)'" -o $(BIN_DIR)/shipsc       ./cmd/client
	@echo "Binaries in $(BIN_DIR)/"

## Clean build artifacts
clean:
	rm -rf $(BIN_DIR)

## Run go vet + staticcheck + fmt check
lint:
	@echo "→ go vet"
	$(GO) vet $(PKG_DIR)
	@if command -v staticcheck >/dev/null; then staticcheck $(PKG_DIR); else echo "staticcheck not installed – skipping"; fi
	@if command -v golangci-lint >/dev/null; then golangci-lint run; else echo "golangci-lint not installed – skipping"; fi
	@output=$$(gofmt -s -l .); if [ -n "$$output" ]; then echo "Code not gofmt'd:" && echo "$$output" && exit 1; fi

## Run unit tests
test:
	$(GO) test -v $(PKG_DIR)

## Cross‑compile Windows client from Linux/macOS
windows:
	GOOS=windows GOARCH=amd64 $(GO) build -trimpath -ldflags "-s -w -X 'main.version=$(VERSION)'" -o $(BIN_DIR)/shipsc.exe ./cmd/client

## Build server binary for Linux (static)
linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build -trimpath -ldflags "-s -w -X 'main.version=$(VERSION)'" -o $(BIN_DIR)/ships-server ./cmd/server

## Produce a versioned release archive (server + client + docs)
release: clean lint test linux windows
	mkdir -p dist/ships2-go-$(VERSION)
	cp -r $(BIN_DIR) docs README.md LICENSE dist/ships2-go-$(VERSION)/
	cd dist && tar czf ships2-go-$(VERSION).tar.gz ships2-go-$(VERSION)
	@echo "Release archive in dist/ships2-go-$(VERSION).tar.gz"

## Initialize development environment
dev-setup:
	@echo "Installing development tools..."
	$(GO) install honnef.co/go/tools/cmd/staticcheck@latest
	@if command -v curl >/dev/null; then \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin; \
	else \
		echo "curl not found, skipping golangci-lint installation"; \
	fi

help:
	@grep -E '^##' $(MAKEFILE_LIST) | cut -c4-
