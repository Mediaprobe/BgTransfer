//
//  BTViewController.m
//  BgTransfer
//
//

#import "BTViewController.h"
#import "BTAppDelegate.h"

@interface BTViewController () <NSURLSessionDelegate>
{
    IBOutlet __weak UIProgressView *_downloadProgressView;
    IBOutlet __weak UIButton *_downloadButton;
    IBOutlet __weak UIButton *_exceptionButton;
    
    IBOutlet __weak UIImageView *_imageView;
    IBOutlet __weak UIButton *_removeButton;
    
    IBOutlet __weak UIActivityIndicatorView *_indicatorView;
    
    NSURLSessionDownloadTask *_downloadTask;
}
@property (nonatomic, readwrite) NSURLSession *session;
@end

NSString *BTImageName = @"eiffel.jpg";
NSString *BTImageURL = @"http://farm9.staticflickr.com/8471/8138794459_749be1bfee_k.jpg"; // 1.4m
//NSString *BTImageURL = @"http://farm9.staticflickr.com/8471/8138794459_6f84a2d835_h.jpg"; // 800kb

@implementation BTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self _eiffelImagePath].path]) {
        _imageView.image = [UIImage imageWithContentsOfFile:[self _eiffelImagePath].path];
    } else {
        _removeButton.hidden = YES;
    }
    
    _exceptionButton.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)downloadAction:(id)sender
{
    _downloadButton.enabled = NO;
    _downloadProgressView.progress = 0;
    
    if (!self.session) {
        [self createSessionWithIdentifier:@"BgTransferId"];
    }
    
    [_indicatorView startAnimating];
    
    _downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:BTImageURL]];
    [_downloadTask resume];
}

- (IBAction)exceptionAction:(id)sender
{
    [[NSException exceptionWithName:@"Arbitrary Exception" reason:@"This exception was raised to confirm background transfer." userInfo:nil] raise];
}

- (IBAction)removeAction:(id)sender
{
    _imageView.image = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[self _eiffelImagePath] error:NULL];
}

- (NSURL*)_eiffelImagePath
{
    NSURL *docUrl = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    docUrl = [docUrl URLByAppendingPathComponent:BTImageName];
    return docUrl;
}

// for shake gesture
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && event.type == UIEventTypeMotion) {
        // show button
        _exceptionButton.hidden = NO;
    }
}

- (void)createSessionWithIdentifier:(NSString*)identifier
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
}

#pragma mark -- NSURLSessionDelegate --

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (_downloadTask != downloadTask) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // update progress
        _downloadProgressView.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    });
}

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // copy image to document directory
    NSURL *docUrl = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    docUrl = [docUrl URLByAppendingPathComponent:BTImageName];

    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:location toURL:docUrl error:NULL];
    if (!success) {
        NSLog(@"Failed to copy. src=%@, dest=%@", location, docUrl);
    }

    if (_downloadTask == downloadTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_indicatorView stopAnimating];
            _downloadButton.enabled = YES;
            _downloadProgressView.progress = 1;
            
            _imageView.image = [UIImage imageWithContentsOfFile:[self _eiffelImagePath].path];
            _removeButton.hidden = NO;
        });
    }
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSLog(@"failed to download: error=%@", error);
        if (task == _downloadTask) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_indicatorView.isAnimating) {
                    [_indicatorView stopAnimating];
                }
            });
        }
#if 0
        if ([error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] intValue] != NSURLErrorCancelledReasonUserForceQuitApplication) {
        
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                // resume
                [[_session downloadTaskWithResumeData:resumeData] resume];
            }
        }
#endif
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        UILocalNotification *notif = [UILocalNotification new];
        notif.alertBody = @"Download Complete.";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
        
        _downloadButton.enabled = YES;
        _downloadProgressView.progress = 1;
        _removeButton.hidden = NO;
        
        _imageView.image = [UIImage imageWithContentsOfFile:[self _eiffelImagePath].path];
    });
    
    BTAppDelegate *appDel = (BTAppDelegate*)[UIApplication sharedApplication].delegate;
    if (appDel.sessionHandler) {
        appDel.sessionHandler();
        appDel.sessionHandler = nil;
    }
}

@end
