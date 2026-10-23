SCHEME     = Poopita
PROJECT    = apps/ios/Poopita.xcodeproj
PACKAGE    = apps/ios/PoopitaKit
DEST      ?= platform=iOS Simulator,name=iPhone 18 Pro
BUNDLE_ID  = com.ayungavis.Poopita
BUILD_LOG  = /tmp/poopita-build.log
TEST_FLAGS ?=

.DEFAULT_GOAL := help

.PHONY: help \
        ios-generate ios-format ios-lint ios-test ios-build ios-run ios-validate

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

ios-run: ios-build ## Build, install, and launch on the booted simulator
	@APP=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -showBuildSettings 2>/dev/null \
		| awk '$$1 == "BUILT_PRODUCTS_DIR" { print $$3; exit }'); \
	xcrun simctl install booted "$$APP/$(SCHEME).app" && \
	xcrun simctl launch booted $(BUNDLE_ID)

ios-validate: ios-format ios-lint ios-test ios-build ## format → lint → test → build
	@echo "✅ iOS OK — format, lint, test, build all green"
