//
//  FrequencyManager.h
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-2.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>
#include <CoreFoundation/CFURL.h>

#import "FFTBufferManager.h"
#import "aurio_helper.h"
#import "CAStreamBasicDescription.h"
#import "AudioUnit/AudioUnit.h"
#import "CAXException.h"
#import "FrequencyDefine.h"

#define SPECTRUM_BAR_WIDTH 4

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif


@interface FrequencyReceiver : NSObject {

	SInt32*						fftData;
	NSUInteger					fftLength;
	BOOL						hasNewFFTData;
	
	AudioUnit					rioUnit;
	BOOL						unitIsRunning;
	BOOL						unitHasBeenCreated;
	
    
	FFTBufferManager*			fftBufferManager;
	DCRejectionFilter*			dcFilter;
	CAStreamBasicDescription	thruFormat;
	Float64						hwSampleRate;
	
	AURenderCallbackStruct		inputProc;
    
	
	int32_t*					l_fftData;
    
	GLfloat*					oscilLine;
	BOOL						resetOscilLine;    
    
    NSTimer*                    timerTracking;
    
}

@property						FFTBufferManager*		fftBufferManager;

@property (nonatomic, assign)	AudioUnit				rioUnit;
@property (nonatomic, assign)	BOOL					unitIsRunning;
@property (nonatomic, assign)	BOOL					unitHasBeenCreated;

@property (nonatomic, assign)	AURenderCallbackStruct	inputProc;


- (BOOL)isTracking;
- (void)startTrack;
- (void)stopTrack;

@end



