#import "AppDelegate.h"
#import "ClipboardMonitor.h"
#import <Carbon/Carbon.h>

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) ClipboardMonitor *monitor;
@property (nonatomic, assign) EventHotKeyRef hotKeyRef;
@end

// Global hotkey callback
static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    AppDelegate *self = (__bridge AppDelegate *)userData;
    [self showMenu];
    return noErr;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Hide dock icon — menu bar only
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    // Create status bar item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"clipboard"
                                             accessibilityDescription:@"ClipStash"];
    self.statusItem.button.image.size = NSMakeSize(16, 16);

    // Start clipboard monitor
    self.monitor = [[ClipboardMonitor alloc] initWithMaxItems:20];

    // Build initial menu
    [self rebuildMenu];

    // Observe clipboard changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rebuildMenu)
                                                 name:@"ClipboardChanged"
                                               object:nil];

    // Register global hotkey: ⌘⇧V
    EventHotKeyID hotKeyID = {.signature = 'CLPS', .id = 1};
    EventTypeSpec eventType = {.eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed};
    InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType, (__bridge void *)self, NULL);
    // kVK_ANSI_V = 0x09, cmdKey | shiftKey
    RegisterEventHotKey(kVK_ANSI_V, cmdKey | shiftKey, hotKeyID,
                        GetApplicationEventTarget(), 0, &_hotKeyRef);
}

- (void)showMenu {
    [self rebuildMenu];
    // Pop up at mouse cursor position
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSMenu *menu = self.statusItem.menu;
    [menu popUpMenuPositioningItem:nil atLocation:mouseLoc inView:nil];
}

- (void)rebuildMenu {
    NSMenu *menu = [[NSMenu alloc] init];
    NSArray<NSString *> *history = self.monitor.history;

    if (history.count == 0) {
        NSMenuItem *empty = [[NSMenuItem alloc] initWithTitle:@"No clipboard history"
                                                      action:nil
                                               keyEquivalent:@""];
        empty.enabled = NO;
        [menu addItem:empty];
    } else {
        for (NSUInteger i = 0; i < history.count; i++) {
            NSString *item = history[i];
            NSString *title = [self truncateString:item maxLength:80];
            NSString *keyEquiv = (i < 9) ? [NSString stringWithFormat:@"%lu", i + 1] : @"";
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title
                                                             action:@selector(pasteItem:)
                                                      keyEquivalent:keyEquiv];
            menuItem.tag = (NSInteger)i;
            menuItem.target = self;
            // Bold the most recent item
            if (i == 0) {
                menuItem.attributedTitle = [[NSAttributedString alloc]
                    initWithString:title
                        attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:13]}];
            }
            [menu addItem:menuItem];
        }
    }

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear History"
                                                      action:@selector(clearHistory:)
                                               keyEquivalent:@""];
    clearItem.target = self;
    [menu addItem:clearItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                     action:@selector(terminate:)
                                              keyEquivalent:@"q"];
    [menu addItem:quitItem];

    self.statusItem.menu = menu;
}

- (void)pasteItem:(NSMenuItem *)sender {
    NSUInteger index = (NSUInteger)sender.tag;
    NSArray<NSString *> *history = self.monitor.history;
    if (index < history.count) {
        NSString *text = history[index];
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:text forType:NSPasteboardTypeString];
        [self.monitor moveToTop:index];
    }
}

- (void)clearHistory:(id)sender {
    [self.monitor clearHistory];
    [self rebuildMenu];
}

- (NSString *)truncateString:(NSString *)string maxLength:(NSUInteger)maxLength {
    // Replace newlines with spaces for display
    NSString *flat = [[string componentsSeparatedByCharactersInSet:
                       [NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    // Collapse multiple spaces
    while ([flat containsString:@"  "]) {
        flat = [flat stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    }
    flat = [flat stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (flat.length <= maxLength) return flat;
    return [[flat substringToIndex:maxLength] stringByAppendingString:@"…"];
}

@end
