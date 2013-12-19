//
//  BTViewController.h
//  BgTransfer
//

#import <UIKit/UIKit.h>

@interface BTViewController : UIViewController
@property (nonatomic, readonly) NSURLSession *session;
- (void)createSessionWithIdentifier:(NSString*)identifier;
- (IBAction)downloadAction:(id)sender;

@end
