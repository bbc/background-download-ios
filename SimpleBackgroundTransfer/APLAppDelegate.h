
/*
     File: APLAppDelegate.h
 Abstract: Application delegate, maintains a completion handler for the background session.
  Version: 1.1
 
*/

@import UIKit;

@interface APLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy) void (^backgroundSessionCompletionHandler)();
@property (nonatomic, readwrite) BOOL CancelDownloadOnAuthChallenge;

@end
