//
//  AudioStream.js
//  AudioStreamer PhoneGap Plugin
//
//  Created by Tommy-Carlos Williams on 20/07/11.
//  Copyright 2011 Devgeeks. All rights reserved.
//

var AudioStream = function(){ 
    
}

AudioStream.prototype.progress = 0;

AudioStream.prototype.play = function(streamUrl, successCallback, failCallback) {
    return PhoneGap.exec("AudioStream.play", streamUrl, GetFunctionName(successCallback), GetFunctionName(failCallback));
};

AudioStream.prototype.stop = function(successCallback, failCallback) {
    return PhoneGap.exec("AudioStream.stop", GetFunctionName(successCallback), GetFunctionName(failCallback));
};

AudioStream.prototype.setProgress = function(progress) {
    AudioStream.prototype.progress = progress;
}

AudioStream.prototype.setStreamType = function(streamType) {
    PhoneGap.exec("AudioStream.setStreamType",streamType);
}

PhoneGap.addConstructor(function(){
    if(!window.plugins)
    {
        window.plugins = {};
    }
    window.plugins.audioStream = new AudioStream();
});