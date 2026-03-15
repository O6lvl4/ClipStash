#import "ClipboardMonitor.h"

NSNotificationName const ClipboardChangedNotification = @"ClipboardChanged";

@interface ClipboardMonitor ()
@property (nonatomic, strong) NSMutableArray<NSString *> *items;
@property (nonatomic, assign) NSUInteger maxItems;
@property (nonatomic, assign) NSInteger lastChangeCount;
@property (nonatomic, strong) NSTimer *pollTimer;
@end

@implementation ClipboardMonitor

- (instancetype)initWithMaxItems:(NSUInteger)maxItems {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _maxItems = maxItems;
        _lastChangeCount = [NSPasteboard generalPasteboard].changeCount;
        // Poll every 0.5s — NSPasteboard has no push notification
        _pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(checkClipboard)
                                                   userInfo:nil
                                                    repeats:YES];
    }
    return self;
}

- (void)checkClipboard {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSInteger currentCount = pb.changeCount;
    if (currentCount == self.lastChangeCount) return;
    self.lastChangeCount = currentCount;

    NSString *text = [pb stringForType:NSPasteboardTypeString];
    if (!text || text.length == 0) return;

    // Deduplicate: remove existing copy
    [self.items removeObject:text];
    // Insert at front
    [self.items insertObject:text atIndex:0];
    // Trim to max
    while (self.items.count > self.maxItems) {
        [self.items removeLastObject];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ClipboardChangedNotification
                                                        object:nil];
}

- (NSArray<NSString *> *)history {
    return [self.items copy];
}

- (void)moveToTop:(NSUInteger)index {
    if (index >= self.items.count) return;
    NSString *item = self.items[index];
    [self.items removeObjectAtIndex:index];
    [self.items insertObject:item atIndex:0];
}

- (void)clearHistory {
    [self.items removeAllObjects];
}

- (void)dealloc {
    [self.pollTimer invalidate];
}

@end
