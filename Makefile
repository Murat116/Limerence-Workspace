ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

MOBILE_DIR := $(ROOT_DIR)/mobile
WEB_DIR := $(ROOT_DIR)/web/editor-app

GIT ?= $(shell which git)

DATE     := $(shell date -u +%Y%m%d)
REVISION := $(shell $(GIT) -C $(ROOT_DIR) rev-parse --short HEAD 2>/dev/null || echo nogit)
TAG      := v$(DATE)-$(REVISION)

APP_NAME := Limerence
IOS_DEVICE_NAME := iPhone 15
ANDROID_EMULATOR_NAME := Pixel_5_API_30

## INSTALL #####################################################################

install: install-mobile install-web ## Install npm deps for mobile and web
.PHONY: install

install-mobile: ## Install mobile npm dependencies
	@cd $(MOBILE_DIR) && npm install
.PHONY: install-mobile

install-web: ## Install web npm dependencies
	@cd $(WEB_DIR) && npm install
.PHONY: install-web

install-ios: install-mobile pod-install ## Install mobile npm + CocoaPods deps
.PHONY: install-ios

pod-install: ## Install iOS CocoaPods dependencies
	@echo "Running pod install..."
	@cd $(MOBILE_DIR)/ios && pod install
.PHONY: pod-install

## MOBILE ######################################################################

start: ## Start React Native Metro packager
	@echo "Starting React Native packager..."
	@cd $(MOBILE_DIR) && npx react-native start
.PHONY: start

ios: ## Run mobile app on iOS Simulator
	@echo "Running on iOS Simulator: $(IOS_DEVICE_NAME)..."
	@cd $(MOBILE_DIR) && npx react-native run-ios --simulator="$(IOS_DEVICE_NAME)"
.PHONY: ios

android: ## Run mobile app on Android emulator
	@echo "Running on Android Emulator: $(ANDROID_EMULATOR_NAME)..."
	@adb devices | grep "device$$" || emulator -avd $(ANDROID_EMULATOR_NAME) &
	@sleep 10
	@cd $(MOBILE_DIR) && npx react-native run-android
.PHONY: android

iphone: ## Run mobile app on iPhone simulator (iphone17.5)
	@echo "Running on iPhone simulator..."
	@cd $(MOBILE_DIR) && npx react-native run-ios --simulator="iphone17.5"
.PHONY: iphone

android-device: ## Run mobile app on connected Android device
	@echo "Running on connected Android device..."
	@cd $(MOBILE_DIR) && npx react-native run-android
.PHONY: android-device

clear-cache: ## Clear Metro bundler cache
	@echo "Clearing Metro bundler cache..."
	@cd $(MOBILE_DIR) && rm -rf node_modules/.cache && npx react-native start --reset-cache
.PHONY: clear-cache

restart: ## Restart Metro with cache reset
	@echo "Restarting mobile packager..."
	@$(MAKE) clear-cache
.PHONY: restart

android-list: ## List available Android Virtual Devices
	@echo "Available Android Virtual Devices (AVDs):"
	@emulator -list-avds
.PHONY: android-list

ios-list: ## List available iOS Simulators
	@echo "Available iOS Simulators:"
	@xcrun simctl list devices | grep -E "iPhone|iPad"
.PHONY: ios-list

android-emulator: ## Launch configured Android emulator
	@echo "Launching Android Emulator: $(ANDROID_EMULATOR_NAME)..."
	@emulator -avd $(ANDROID_EMULATOR_NAME) &
	@sleep 10
.PHONY: android-emulator

ios-release: ## Build iOS release scheme for simulator
	@echo "Building iOS release scheme..."
	@cd $(MOBILE_DIR)/ios && xcodebuild \
		-workspace $(APP_NAME).xcworkspace \
		-scheme $(APP_NAME) \
		-configuration Release \
		-sdk iphonesimulator \
		-derivedDataPath build
.PHONY: ios-release

mobile-lint: ## Lint mobile codebase
	@cd $(MOBILE_DIR) && npm run lint
.PHONY: mobile-lint

mobile-test: ## Run mobile unit tests
	@cd $(MOBILE_DIR) && npm run test
.PHONY: mobile-test

## WEB #########################################################################

web: web-dev ## Start web editor dev server (alias for web-dev)
.PHONY: web

web-dev: ## Start Vite dev server for editor-app
	@echo "Starting web editor dev server..."
	@cd $(WEB_DIR) && npm run dev
.PHONY: web-dev

web-build: ## Build web editor for production
	@cd $(WEB_DIR) && npm run build
.PHONY: web-build

web-preview: ## Preview production web build
	@cd $(WEB_DIR) && npm run preview
.PHONY: web-preview

web-lint: ## Lint web editor codebase
	@cd $(WEB_DIR) && npm run lint
.PHONY: web-lint

web-test: ## Run web editor tests
	@cd $(WEB_DIR) && npm run test:run
.PHONY: web-test

## DEPLOY ######################################################################

upload-ios: ## Archive and upload iOS build to App Store Connect
	@echo "Archiving for iOS..."
	@cd $(MOBILE_DIR) && xcodebuild \
		-workspace ios/$(APP_NAME).xcworkspace \
		-scheme $(APP_NAME) \
		-configuration Release \
		-archivePath ios/build/$(APP_NAME).xcarchive \
		CODE_SIGN_STYLE=Manual \
		CODE_SIGN_IDENTITY="iPhone Distribution: Ekaterina Linkevich (68ZUNCT45S)" \
		PROVISIONING_PROFILE_SPECIFIER="YourDistributionProfileName" \
		PRODUCT_BUNDLE_IDENTIFIER="com.yourcompany.$(APP_NAME)" \
		clean archive
	@echo "Exporting IPA..."
	@cd $(MOBILE_DIR) && xcodebuild \
		-exportArchive \
		-archivePath ios/build/$(APP_NAME).xcarchive \
		-exportPath ios/build/ipa \
		-exportOptionsPlist ios/exportOptions.plist
	@echo "Uploading to App Store Connect..."
	@xcrun altool --upload-app \
		--type ios \
		--file $(MOBILE_DIR)/ios/build/ipa/$(APP_NAME).ipa \
		--username "$(APPLE_ID_EMAIL)" \
		--password "$(APP_SPECIFIC_PASSWORD)"
.PHONY: upload-ios

## HELP ########################################################################

help: ## Show this help
	@echo ""
	@echo "Limerence workspace — run from repo root:"
	@echo ""
	@echo "  Mobile:  make start | ios | android | iphone | android-device"
	@echo "  Web:     make web | web-dev | web-build | web-preview"
	@echo ""
	@grep -hE '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;36m%-20s\033[m %s\n", $$1, $$2}'
	@echo ""
.PHONY: help

.DEFAULT_GOAL := help
