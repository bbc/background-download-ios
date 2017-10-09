/*
     File: APLViewController.m
 Abstract: Main view controller; manages a URLSession.
  Version: 1.1
 
*/

#import "APLViewController.h"
#import "APLAppDelegate.h"
#import <VideoPlayer/VideoPlayerError.h>
#import <VideoPlayer/VideoPlayerView.h>
#import <VideoPlayer/VideoPlayerViewController.h>
#import "UIForLumberjack.h"


//int ddLogLevel = DDLogLevelVerbose;



@interface APLViewController () <VideoPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIView *loggerView;
@property (weak, nonatomic) IBOutlet UIView *videoPlayerView;
@property (retain, nonatomic) VideoPlayerViewController *videoPlayerController;

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSession *anipSession;

@property (nonatomic) NSURLSessionDownloadTask *currentDownloadTask;
@property (nonatomic) NSArray *videoSegments;
@property (nonatomic) NSMutableArray *downloadTasks;
@property (weak, nonatomic) IBOutlet UIView *progressBarsView;

// Progress views statically created for prototyping purposes


@end


@implementation APLViewController
{
    NSMutableDictionary *progressBarMap;
    NSMutableArray* playQueue;
    NSUInteger playIndex;
    NSTimer *schedulerTimer;
    NSUInteger downloadIndex;
    APLAppDelegate* app_delegate;
    NSString* proxyHost;
    NSNumber* proxyPort;

    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    app_delegate = (APLAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [[UIForLumberjack sharedInstance] showLogInView:_loggerView];
    proxyHost = @"192.168.0.106";
    proxyPort = [NSNumber numberWithInt: 8888];
    self.videoPlayerView.hidden = YES;
    self.videoSegments = [NSArray arrayWithObjects:
                          @"http://192.168.0.110:8080/channelA1.mp4",
                          @"http://192.168.0.110:8080/channelA2.mp4",
                          @"http://192.168.0.110:8080/channelA3.mp4",
                          @"http://192.168.0.110:8080/channelA4.mp4",
                          @"http://192.168.0.110:8080/channelA5.mp4",
                          @"http://192.168.0.110:8080/channelA6.mp4",
                          @"http://192.168.0.110:8080/channelA7.mp4",
                          @"http://192.168.0.110:8080/channelA8.mp4",

                          nil];
    progressBarMap = [[NSMutableDictionary alloc] init];
    playQueue = [[NSMutableArray alloc] init];
    
    DDLogInfo(@"app_delegate.CancelDownloadOnAuthChallenge: %d", app_delegate.CancelDownloadOnAuthChallenge);
    
   
    
    self.session = [self backgroundSession];
    self.anipSession = [self createAnipSession];
}


- (IBAction)start:(id)sender
{
    
    NSUInteger numDownloads = self.videoSegments.count;
    int posX = self.progressBarsView.bounds.origin.x;
    int height = self.progressBarsView.bounds.size.height;
//    int posY = self.progressBarsView.bounds.origin.y + height;
    int width = self.progressBarsView.bounds.size.width / numDownloads;
    
    if (self.currentDownloadTask)
    {
        return;
    }
    
    for (NSString* downloadURLString in self.videoSegments) {
        
        // create progress bars
        UIProgressView *progress_bar = [[UIProgressView alloc] init];
        [_progressBarsView addSubview:progress_bar];
        progress_bar.progress = 0;
        [[progress_bar layer]setFrame:CGRectMake(posX, height/2, width, 10)];
        [progressBarMap setObject:progress_bar forKey:downloadURLString];
        
        
        // create download tasks
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString ];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
        [downloadTask resume];
        DDLogInfo(@"Downloading %@ ...", downloadURLString);
      
        
        posX += width;
    }
    
    self.videoPlayerView.hidden = YES;
    
    }


- (NSURLSession*) createAnipSession
{
    static NSURLSession *anipSession = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *anipSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSDictionary *proxyDict = @{@"kCFNetworkProxiesHTTPEnable" : @YES,
                                    (NSString *)kCFNetworkProxiesHTTPProxy : proxyHost,
                                    (NSString *)kCFNetworkProxiesHTTPPort : proxyPort};
        
        anipSessionConfiguration.connectionProxyDictionary = proxyDict;
        anipSessionConfiguration.HTTPMaximumConnectionsPerHost = 1;

        anipSession = [NSURLSession sessionWithConfiguration:anipSessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return anipSession;
    
}


- (NSURLSession *)backgroundSession
{
/*
 Using dispatch_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
 */
    
 	static NSURLSession *session = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"uk.bbc.rd.SimpleBackgroundTransfer.BackgroundSession"];
        
        NSDictionary *proxyDict = @{@"kCFNetworkProxiesHTTPEnable" : @YES,
                                    (NSString *)kCFNetworkProxiesHTTPProxy : proxyHost,
                                    (NSString *)kCFNetworkProxiesHTTPPort : proxyPort};
        
        configuration.connectionProxyDictionary = proxyDict;
        configuration.HTTPMaximumConnectionsPerHost = 1;
        
		session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
	});
	return session;
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    BLog();
    self.currentDownloadTask = downloadTask;
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */
    
    // get downloadtask's progress bar
    NSString *urlString =  [downloadTask.originalRequest.URL absoluteString];
    UIProgressView *progressbar = [progressBarMap objectForKey:urlString];
    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    BLog(@"DownloadTask: %@ progress: %lf", downloadTask, progress);
    
    if (progressbar)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressbar.progress = progress;
        });
    }
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    BLog();
}



- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    BLog();

    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
    */
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];

    NSURL *originalURL = [[downloadTask originalRequest] URL];
    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
    NSError *errorCopy;

    // For the purposes of testing, remove any existing file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    BOOL success = [fileManager copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    
    if (success)
    {
        // add file to playqueue
        [playQueue addObject:destinationURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            [self scheduleVideoPlayer];
        
        });
        
        DDLogInfo(@"Finished downloading %@ ...", originalURL.absoluteString);
    }
    else
    {
        /*
         In the general case, what you might do in the event of failure depends on the error and the specifics of your ap.plication.
         */
        BLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
    }
    
    
}




- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    BLog();

    if (error == nil)
    {
        DDLogInfo(@"Task: %@ completed successfully", task);
    }
    else
    {
        DDLogInfo(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
    }
    // get downloadtask's progress bar
    NSString *urlString =  [task.originalRequest.URL absoluteString];
    UIProgressView *progressbar = [progressBarMap objectForKey:urlString];
    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
	
    if (progressbar)
    {
        progressbar.progress = progress;
    }
    
    self.currentDownloadTask = nil;
}



/*
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    APLAppDelegate *appDelegate = (APLAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }

    NSLog(@"All tasks are finished");
}




- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    // can we detect a challenge?
    // Does a 401 response trigger a challenge or an event
    
    DDLogInfo(@"Received authentication challenge: %@ error: %@", challenge.failureResponse.URL.absoluteString, [challenge.error localizedDescription] );
    
    
    // send an ANIP request via data task
    
    
    
    
    if (app_delegate.CancelDownloadOnAuthChallenge){
        
        DDLogInfo(@"Cancelling background download session");
        [self.session invalidateAndCancel];
    }
    
    
//    if (completionHandler)
//        completionHandler(nil, nil);
}
//------------------------------------------------------------------------------
#pragma mark - Private methods
//------------------------------------------------------------------------------
- (void) scheduleVideoPlayer
{
    
    if (playQueue.count > 0 )
    {
        if (!_videoPlayerController)
        {
            _videoPlayerController = [[VideoPlayerViewController alloc] initWithParentView:self.videoPlayerView
                                                                                  Delegate:self];
            NSURL *url = [playQueue objectAtIndex:0];
            _videoPlayerController.videoURL = url;
            playIndex = 0;
            self.videoPlayerView.hidden =NO;
            [self.view bringSubviewToFront:self.videoPlayerView];
            [self.videoPlayerView bringSubviewToFront:self.videoPlayerController.videoPlayer];
            
        }
    }
}


//------------------------------------------------------------------------------
#pragma mark - VideoPlayerDelegate methods
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------


-(void) VideoPlayer:(VideoPlayerView *) videoplayer
              State:(VideoPlayerState) state{
    
    //DDLogInfo(@"VideoPlayer.state: %lu", state);
    
    if (state == VideoPlayerStateReadyToPlay) [self.videoPlayerController play];
    [self.view bringSubviewToFront:self.videoPlayerView];
    [self.videoPlayerView bringSubviewToFront:self.videoPlayerController.videoPlayer];
    
    
    
    
}

//------------------------------------------------------------------------------


- (void)VideoPlayer:(VideoPlayerView *) videoplayer
    updatedPosition:(NSTimeInterval) time
{
    
}

//------------------------------------------------------------------------------


- (void)VideoPlayer:(VideoPlayerView *)videoplayer
reachedEndOfVideoFile:(AVPlayerItem *) videoAsset
{
    if (playIndex < (playQueue.count -1))
    {
        playIndex++;
        
        _videoPlayerController.videoURL = [playQueue objectAtIndex:playIndex];
        
    }
}

//------------------------------------------------------------------------------

- (void) VideoPlayer:(VideoPlayerView *)videoplayer
   DurationAvailable:(NSTimeInterval) duration
{
    //DDLogInfo(@"VideoPlayer.duration: %f", duration);
}

//------------------------------------------------------------------------------

- (void) VideoPlayer:(VideoPlayerView *)videoplayer
  TrackInfoAvailable:(NSArray<AVPlayerItemTrack *>*) tracks
{
    //DDLogInfo(@"VideoPlayer item tracks: %@", tracks);
}

//------------------------------------------------------------------------------

- (void) VideoPlayer:(VideoPlayerView *)videoplayer
    LoadedTimeRanges:(NSArray*) ranges
{
    //DDLogInfo(@"VideoPlayer buffering status: %@", ranges);
       
}


//------------------------------------------------------------------------------


@end
