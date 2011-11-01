//
//  AudioStream.js
//  AudioStreamer PhoneGap Plugin
//
//  Created by Tommy-Carlos Williams on 20/07/11.
//  Copyright 2011 Devgeeks. All rights reserved.
//

var AudioStream = {
    
	play: function(streamUrl, successCallback, failCallback) {
		return PhoneGap.exec(successCallback, failCallback, "AudioStream", "play", [streamUrl]);
	},
	stop: function(successCallback, failCallback) {
		return PhoneGap.exec(successCallback, failCallback, "AudioStream", "stop", []);
	},
	setProgress: function(progress) {
		this.progress = progress;
	},
	setStreamType: function(streamType) {
		return PhoneGap.exec(null, null, "AudioStream", "setStreamType", [streamType]);
	}
};
if(!window.plugins)
{
	window.plugins = {};
}
window.plugins.audioStream = AudioStream;

