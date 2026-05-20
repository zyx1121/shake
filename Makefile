APP_NAME    := Shake
BUNDLE_ID   := dev.zyx1121.shake
BUILD_CONF  := release
BIN_PATH    := .build/$(BUILD_CONF)/$(APP_NAME)
APP_BUNDLE  := build/$(APP_NAME).app
CONTENTS    := $(APP_BUNDLE)/Contents
MACOS_DIR   := $(CONTENTS)/MacOS
RES_DIR     := $(CONTENTS)/Resources

# Apple Development: yongxiang.zhan@outlook.com (FJW6JALJHP)
SIGN_ID     := 53522E3FA5C4B3895923E59B64C70D38ECEF6FBC

.PHONY: all build bundle run clean rebuild

all: bundle

build:
	swift build -c $(BUILD_CONF)

bundle: build
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(MACOS_DIR) $(RES_DIR)
	@cp $(BIN_PATH) $(MACOS_DIR)/$(APP_NAME)
	@cp Resources/Info.plist $(CONTENTS)/Info.plist
	@codesign --force --deep --options runtime --sign $(SIGN_ID) $(APP_BUNDLE)
	@echo "[OK] $(APP_BUNDLE) built and signed with Apple Development cert"

run: bundle
	open $(APP_BUNDLE)

rebuild: clean bundle

clean:
	rm -rf .build build
