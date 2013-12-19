//
//  BTAppDelegate.h
//  BgTransfer
//

#import <UIKit/UIKit.h>

@interface BTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) void (^sessionHandler)(void);
@end
