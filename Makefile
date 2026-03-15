APP_NAME = ClipStash
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
SOURCES = ClipStash/main.m ClipStash/AppDelegate.m ClipStash/ClipboardMonitor.m
FRAMEWORKS = -framework Cocoa -framework Carbon
CFLAGS = -fobjc-arc -mmacosx-version-min=12.0

.PHONY: all clean install run

all: $(APP_BUNDLE)

$(APP_BUNDLE): $(SOURCES)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp ClipStash/Info.plist $(APP_BUNDLE)/Contents/
	clang $(CFLAGS) $(FRAMEWORKS) $(SOURCES) -o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@echo "Built: $(APP_BUNDLE)"

install: $(APP_BUNDLE)
	@rm -rf /Applications/$(APP_NAME).app
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

run: $(APP_BUNDLE)
	@open $(APP_BUNDLE)

clean:
	@rm -rf $(BUILD_DIR)
