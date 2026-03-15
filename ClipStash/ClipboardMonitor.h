#import <Cocoa/Cocoa.h>

extern NSNotificationName const ClipboardChangedNotification;

@interface ClipboardMonitor : NSObject

@property (nonatomic, readonly) NSArray<NSString *> *history;

- (instancetype)initWithMaxItems:(NSUInteger)maxItems;
- (void)moveToTop:(NSUInteger)index;
- (void)clearHistory;

@end
