//
//  AudioStream.m
//  AudioStreamer PhoneGap Plugin
//
//  Created by Tommy-Carlos Williams on 20/07/11.
//  Copyright 2011 Devgeeks. All rights reserved.
//
//  Borrowing heavily from the iPhoneStreamingPlayerViewController from 
//      Matt Gallagher's AudioStreamer sample application that goes with his 
//      AudioStreamer Classes this plugin is implementing

#import "AudioStream.h"
#import "AudioStreamer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

@implementation ResponderView
@synthesize delegate;

// Override canBecomeFirstResponder to receieve remote control events
-(BOOL)canBecomeFirstResponder 
{
	return YES;
}

// Process remote control events
-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	switch (event.subtype) {
		case UIEventSubtypeRemoteControlTogglePlayPause:
			[[self delegate] playPauseEvent:self];
			break;
		default:
			break;
	}
}
- (void)setup {	
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version >= 4.0) {
		// Tell system to receive remote control events
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		[self becomeFirstResponder];
	}
}

- (void)dealloc {
	[super dealloc];
}

@end

@implementation AudioStream

@synthesize /*successCallback, failCallback,*/ status, streamUrl, progressString, streamType, responderView, callbackId;

#ifndef __IPHONE_3_0
@synthesize webView;
#endif

-(PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (AudioStream*)[super initWithWebView:theWebView];
#if __IPHONE_4_0
	CGRect viewRect = CGRectMake(0,0,1,1); // can it be all zeros or be hidden?
	self.responderView = [[[ResponderView alloc] initWithFrame:viewRect] autorelease];
	self.responderView.delegate = self;
	[self.webView.superview addSubview:self.responderView];
	self.responderView.hidden = YES;
#endif
    return self;
}

#pragma mark -
#pragma mark creation and destruction
//
// destroyStreamer
//
// Removes the streamer, the UI update timer and the change notification
//
- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ASStatusChangedNotification
                                                      object:streamer];
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
		
		[streamer stop];
		//[streamer release];
		streamer = nil;
        
		if (self.callbackId) {
			PluginResult* result = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:@"isStopped"];
			[result setKeepCallbackAsBool:YES];
			[super writeJavascript:[result toSuccessCallbackString:self.callbackId]];
			NSLog(@"%@",@"isStopped");
		}
		/*
		NSString* jsCallBack = [NSString stringWithFormat:@"%@(\"%@\");", self.successCallback, @"isStopped"];
        [self writeJavascript: jsCallBack];
		*/
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (void)createStreamer
{
	if (streamer)
	{
		return;
	}
    
	[self destroyStreamer];
    self.progressString = [[[NSString alloc] initWithString:@""] autorelease];
	
	NSString *escapedValue = [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                  nil,
                                                                                  (CFStringRef)streamUrl,
                                                                                  NULL,
                                                                                  NULL,
                                                                                  kCFStringEncodingUTF8)
                              autorelease];
	
	NSURL *url = [NSURL URLWithString:escapedValue];
    
	streamer = [[AudioStreamer alloc] initWithURL:url];
    if (self.streamType) 
    {
        streamer.fileExtension = self.streamType;
    }
	
	progressUpdateTimer = [NSTimer
                           scheduledTimerWithTimeInterval:0.1
                           target:self
                           selector:@selector(updateProgress:)
                           userInfo:nil
                           repeats:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:streamer];
#if __IPHONE_4_0
	if (self.responderView) [self.responderView setup];
#endif
}

#pragma mark -
#pragma mark playback controls

- (void) setStreamType:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	/*
    NSUInteger argc = [arguments count];
	
	if (argc < 1) { // at a minimum we need a url and a success callback
		return;	
	}
	*/
	
    self.streamType = [arguments objectAtIndex:1];
}
//
// play:
//
// Parameters: 
//      streamUrl - url to stream
//
- (void) play:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	self.callbackId = arguments.pop;
	self.streamUrl = [arguments objectAtIndex:0];
	[self createStreamer];
    [streamer start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	/*
    NSUInteger argc = [arguments count];
	
	if (argc < 2) { // at a minimum we need a url and a success callback
		return;	
	}
    
    self.streamUrl = [arguments objectAtIndex:0];
    
    if (argc > 1) {
        self.successCallback = [arguments objectAtIndex:1];
    }
    
	if (argc > 2) {
		self.failCallback = [arguments objectAtIndex:2];	
	}
    
    [self createStreamer];
    [streamer start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	 */
}

//
// stop:
//
// Parameters: 
//      streamUrl - url to stream
//
- (void)stop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self destroyStreamer];
}

- (void) playPauseEvent:(ResponderView *)tutorial
{
	if (streamer) 
	{
		[self destroyStreamer];
	}
	else
	{
		[self createStreamer];
		[streamer start];
	}
}

#pragma mark -
#pragma mark state callbacks

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{ 
	if ([streamer error] && [streamer errorMessage])
	{
		if (self.callbackId) {
			PluginResult* result = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[streamer error],@"error",[streamer errorMessage],@"errorMessage", nil]];
			[result setKeepCallbackAsBool:YES];
			[super writeJavascript:[result toErrorCallbackString:self.callbackId]];
		}
		/*
		 NSString* jsCallBack = [NSString stringWithFormat:@"%@({'error':'%@','errorMessage':'%@'});", self.failCallback, streamer.error, streamer.errorMessage];
		 [self writeJavascript: jsCallBack];
		 */
		
	}
	if ([streamer isWaiting])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		[self setStatus:@"isWaiting"];
	}
	else if ([streamer isPaused])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[self setStatus:@"isPaused"];
	}
	else if ([streamer isPlaying])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[self setStatus:@"isPlaying"];
	}
	else if ([streamer isIdle])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[self destroyStreamer];
		[self setStatus:@"isIdle"];
	}
	
	
	
	if (self.callbackId) {
		PluginResult* result = [PluginResult resultWithStatus:PGCommandStatus_OK messageAsString:status];
		[result setKeepCallbackAsBool:YES];
		[super writeJavascript:[result toSuccessCallbackString:self.callbackId]];
		NSLog(@"STATUS: %@",status);
	}
	/*
	NSString* jsCallBack = [NSString stringWithFormat:@"%@('%@');", self.successCallback, status];
	[self writeJavascript: jsCallBack];
	*/
}


//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{    
	if (streamer.bitRate != 0.0)
	{
		double progress = streamer.progress;

		if (progress > 0)
		{
			self.progressString = [NSString stringWithFormat:@"%.1f",
                              progress];
		}
	}
	
    NSString* jsCallBack = [NSString stringWithFormat:@"AudioStream.setProgress('%@')",self.progressString];
    [super writeJavascript: jsCallBack];
}

#pragma mark -
#pragma mark dealloc and cleanup

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[self destroyStreamer];
    
	if (progressUpdateTimer)
	{
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
	}
    
    [status release];
    status = nil;
    	
	[streamer release];
	streamer = nil;
	
    [super dealloc];
}


@end
