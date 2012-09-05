//
//  FrequencySender.h
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-2.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FrequencyDefine.h"

@interface FrequencySender : NSObject {
	AudioComponentInstance toneUnit;
    
@public
	double frequency;
	double sampleRate;
	double theta;
}


- (void)playTone:(double)frequency;
- (void)stopTone;
- (BOOL)isPlaying;

@end
