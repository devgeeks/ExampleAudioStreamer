//
//  AudioStream.h
//  AudioStreamer PhoneGap Plugin
//
//  Created by Tommy-Carlos Williams on 20/07/11.
//  Copyright 2011 Devgeeks. All rights reserved.
//

#ifdef PHONEGAP_FRAMEWORK
    #import <PhoneGap/PGPlugin.h>
#else
    #import "PGPlugin.h"
#endif

#import "AudioStreamer.h"
#import <UIKit/UIkit.h>

@protocol ResponderViewDelegate;
@interface ResponderView: UIView {
	id <ResponderViewDelegate> delegate;
}

@property (nonatomic, assign) id <ResponderViewDelegate> delegate;

@end

@protocol ResponderViewDelegate <NSObject>
@optional
- (void)playPauseEvent:(ResponderView *)tutorial;
@end

@interface AudioStream : PGPlugin <ResponderViewDelegate> {
    AudioStreamer* streamer;
	NSTimer* progressUpdateTimer;
	
	NSString* callbackId;
    
//    NSString* successCallback;
//    NSString* failCallback;
    NSString* status;
    NSString* streamUrl;
    NSString* progressString;
    NSString* streamType;

	ResponderView* responderView;
}

@property (nonatomic, copy) NSString* callbackId;

//@property (nonatomic, copy) NSString* successCallback;
//@property (nonatomic, copy) NSString* failCallback;
@property (nonatomic, copy) NSString* status;
@property (nonatomic, copy) NSString* streamUrl;
@property (nonatomic, copy) NSString* progressString;
@property (nonatomic, copy) NSString* streamType;

@property (nonatomic, assign) ResponderView* responderView;

- (void)play:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)stop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
