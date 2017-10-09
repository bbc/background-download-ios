/*
     File: APLAppDelegate.m
 Abstract: Main view controller; manages a URLSession.
  Version: 1.1
 

 */

#import "APLAppDelegate.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

#import "UIForLumberjack.h"

#define LOG_ASYNC_ENABLED YES

int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation APLAppDelegate
{
    NSUserDefaults *defaults;
}

- (void) initializeLoggers {
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    
    [DDLog addLogger:[UIForLumberjack sharedInstance]];
    
    DDLogInfo(@"All loggers added successfully");
    
    
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    BLog();
    /*
     Store the completion handler. The completion handler is invoked by the view controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been completed).
     */
	self.backgroundSessionCompletionHandler = completionHandler;
}


-(void)applicationWillResignActive:(UIApplication *)application
{
    BLog();
}


-(void)applicationDidBecomeActive:(UIApplication *)application
{
    BLog();
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeLoggers];
    [self registerDefaultsFromSettingsBundle];
     defaults = [NSUserDefaults standardUserDefaults];
    self.CancelDownloadOnAuthChallenge = [defaults boolForKey:@"cancel_download"];
    
    return YES;
}


- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}


@end
