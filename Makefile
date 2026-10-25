SCHEME     = Poopita
PROJECT    = apps/ios/Poopita.xcodeproj
PACKAGE    = apps/ios/PoopitaKit
DEST      ?= platform=iOS Simulator,name=iPhone 18 Pro
BUNDLE_ID  = com.ayungavis.Poopita
BUILD_LOG  = /tmp/poopita-build.log
TEST_FLAGS ?=

.DEFAULT_GOAL := help

.PHONY: help \
        ios-generate ios-format ios-lint ios-test ios-build ios-storage-smoke ios-startup-smoke ios-run ios-validate

## Descriptions come from the `##` comments below, so this list cannot go stale.
help:
	@echo "Poopita — iOS app (apps/ios/)"
	@echo
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# ------------------------------------------------------------------- iOS

ios-generate: ## Regenerate Poopita.xcodeproj from project.yml
	cd apps/ios && xcodegen generate

ios-format: ## Format iOS Swift sources
	swiftformat apps/ios

ios-lint: ## SwiftLint in strict mode
	swiftlint --strict

ios-test: ## Unit tests via swift test — no simulator needed
	swift test --package-path $(PACKAGE) --build-system swiftbuild $(TEST_FLAGS)

# xcodebuild output is huge — log to a file, print the tail only on failure.
ios-build: ios-generate ## Build for the iPhone simulator
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' build > $(BUILD_LOG) 2>&1 \
		&& grep -E '^\*\* BUILD' $(BUILD_LOG) \
		|| (tail -30 $(BUILD_LOG); exit 1)

ios-storage-smoke: ## Check real storage on the booted simulator
	@set -eu; \
	SMOKE_DIR=$$(mktemp -d /tmp/poopita-storage-smoke.XXXXXX); \
	trap 'rm -rf "$$SMOKE_DIR"' EXIT; \
	SDK_PATH=$$(xcrun --sdk iphonesimulator --show-sdk-path); \
	xcrun --sdk iphonesimulator swiftc -swift-version 6 \
		-target "$$(uname -m)-apple-ios26.0-simulator" -sdk "$$SDK_PATH" \
		$(PACKAGE)/Sources/PoopitaKit/Core/AppError.swift \
		$(PACKAGE)/Sources/PoopitaKit/Core/Stores/SwiftDataValueStore.swift \
		$(PACKAGE)/Sources/PoopitaKit/Utilities/ProtectedStorage.swift \
		apps/ios/SmokeTests/StorageSmoke.swift -o "$$SMOKE_DIR/StorageSmoke"; \
	xcrun simctl spawn booted "$$SMOKE_DIR/StorageSmoke"

ios-startup-smoke: ## Read-only Today startup check; app must be running without a debugger
	@set -eu; \
	APP_PID=$$(xcrun simctl spawn booted launchctl list \
		| awk '$$3 ~ /^UIKitApplication:com\.ayungavis\.Poopita\[/ { print $$1 }'); \
	test -n "$$APP_PID" || { echo "Poopita is not running on the booted simulator"; exit 1; }; \
	xcrun lldb --batch -p "$$APP_PID" -s apps/ios/SmokeTests/StartupSmoke.lldb

ios-run: ios-build ios-storage-smoke ## Build, check storage, install, and launch on the booted simulator
	@APP=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -showBuildSettings 2>/dev/null \
		| awk '$$1 == "BUILT_PRODUCTS_DIR" { print $$3; exit }'); \
	xcrun simctl install booted "$$APP/$(SCHEME).app" && \
	xcrun simctl launch booted $(BUNDLE_ID)

ios-validate: ios-format ios-lint ios-test ios-build ## format → lint → test → build
	@echo "✅ iOS OK — format, lint, test, build all green"
