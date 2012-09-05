//
//  FrequencyManager.m
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-2.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import "FrequencyReceiver.h"
#import "VPUtil.h"




@implementation FrequencyReceiver

@synthesize rioUnit;
@synthesize unitIsRunning;
@synthesize unitHasBeenCreated;
@synthesize fftBufferManager;
@synthesize inputProc;

- (id)init
{
    self = [super init];
    if (self) {
        [self initAudio];
        
    }
    
    return self;
}

- (BOOL)isTracking
{
    return timerTracking!=nil;
}

- (void)startTrack
{
    [timerTracking invalidate];
    [timerTracking release], timerTracking = nil;
    timerTracking = [[NSTimer scheduledTimerWithTimeInterval:1/10.f target:self selector:@selector(checkFrequency) userInfo:nil repeats:YES] retain];
}

- (void)stopTrack
{
    if ([self isTracking]) {
        [timerTracking invalidate];
        [timerTracking release], timerTracking = nil;
    }    
}


#pragma mark-

void cycleOscilloscopeLines()
{
	// Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	int drawBuffer_i;
	for (drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
		memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], drawBufferLen);
}

#pragma mark -Audio Session Interruption Listener

void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
	printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	FrequencyReceiver *THIS = (FrequencyReceiver*)inClientData;
	
	if (inInterruption == kAudioSessionEndInterruption) {
		// make sure we are again the active session
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active");
		XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
	}
	
	if (inInterruption == kAudioSessionBeginInterruption) {
		XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
    }
}

#pragma mark -Audio Session Property Listener

void propListener(	void *                  inClientData,
                  AudioSessionPropertyID	inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
	FrequencyReceiver *THIS = (FrequencyReceiver*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try {
            UInt32 isAudioInputAvailable; 
            UInt32 size = sizeof(isAudioInputAvailable);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isAudioInputAvailable), "couldn't get AudioSession AudioInputAvailable property value");
            
            if(THIS->unitIsRunning && !isAudioInputAvailable)
            {
                XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
                THIS->unitIsRunning = false;
            }
            
            else if(!THIS->unitIsRunning && isAudioInputAvailable)
            {
                XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
                
                if (!THIS->unitHasBeenCreated)	// the rio unit is being created for the first time
                {
                    XThrowIfError(SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat), "couldn't setup remote i/o unit");
                    THIS->unitHasBeenCreated = true;
                    
                    THIS->dcFilter = new DCRejectionFilter[THIS->thruFormat.NumberChannels()];
                    
                    UInt32 maxFPS;
                    size = sizeof(maxFPS);
                    XThrowIfError(AudioUnitGetProperty(THIS->rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
                    
                    THIS->fftBufferManager = new FFTBufferManager(maxFPS);
                    THIS->l_fftData = new int32_t[maxFPS/2];
                    
                    THIS->oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
                }
                
                XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
                THIS->unitIsRunning = true;
            }
		} catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
	}
}

#pragma mark -RIO Render Callback

static OSStatus	PerformThru(
							void						*inRefCon, 
							AudioUnitRenderActionFlags 	*ioActionFlags, 
							const AudioTimeStamp 		*inTimeStamp, 
							UInt32 						inBusNumber, 
							UInt32 						inNumberFrames, 
							AudioBufferList 			*ioData)
{
	FrequencyReceiver *THIS = (FrequencyReceiver *)inRefCon;
	OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
	
	// Remove DC component
	for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
		THIS->dcFilter[i].InplaceFilter((SInt32*)(ioData->mBuffers[i].mData), inNumberFrames, 1);
    
    // The draw buffer is used to hold a copy of the most recent PCM data to be drawn on the oscilloscope
    if (drawBufferLen != drawBufferLen_alloced)
    {
        int drawBuffer_i;
        
        // Allocate our draw buffer if needed
        if (drawBufferLen_alloced == 0)
            for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
                drawBuffers[drawBuffer_i] = NULL;
        
        // Fill the first element in the draw buffer with PCM data
        for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
        {
            drawBuffers[drawBuffer_i] = (SInt8 *)realloc(drawBuffers[drawBuffer_i], drawBufferLen);
            bzero(drawBuffers[drawBuffer_i], drawBufferLen);
        }
        
        drawBufferLen_alloced = drawBufferLen;
    }
    
    
    if (THIS->fftBufferManager == NULL) return noErr;
    
    if (THIS->fftBufferManager->NeedsNewAudioData())
    {
        THIS->fftBufferManager->GrabAudioData(ioData); 
    }
    
	SilenceData(ioData);// 静音好像是
	
	return err;
}

#pragma mark-
#pragma makr- audio init
- (void)initAudio
{
    // Initialize our remote i/o unit
	inputProc.inputProc = PerformThru;
	inputProc.inputProcRefCon = self;
    
	try {			
		// Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");
        
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
		XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self), "couldn't set property listener");
        
		Float32 preferredBufferSize = .005;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
		
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
		XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
		unitHasBeenCreated = true;
		
		dcFilter = new DCRejectionFilter[thruFormat.NumberChannels()];
        
		UInt32 maxFPS;
		size = sizeof(maxFPS);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
		
		fftBufferManager = new FFTBufferManager(maxFPS);
		l_fftData = new int32_t[maxFPS/2];
		
		oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
        
		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
		size = sizeof(thruFormat);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
		
		unitIsRunning = 1;
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
	}
}

- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH
{
	if (LENGTH != fftLength)
	{
		fftLength = LENGTH;
		fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
	}
	memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
	hasNewFFTData = YES;
}

- (void)checkFrequency
{
    if (fftBufferManager->HasNewAudioData())
    {
        if (fftBufferManager->ComputeFFT(l_fftData))
            [self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
        else
            hasNewFFTData = NO;
    }
    
    if (hasNewFFTData)
    {
        int y, maxY;
        maxY = drawBufferLen;
        for (y=0; y<maxY; y++)
        {
            CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
            CGFloat fftIdx = yFract * ((CGFloat)fftLength);
            
            double fftIdx_i, fftIdx_f;
            fftIdx_f = modf(fftIdx, &fftIdx_i);
            
            SInt8 fft_l, fft_r;
            CGFloat fft_l_fl, fft_r_fl;
            CGFloat interpVal;
            
            fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
            fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
            fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
            fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
            interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
            
            interpVal = CLAMP(0., interpVal, 1.);
            
            drawBuffers[0][y] = (interpVal * 120);
        }
        cycleOscilloscopeLines();
    }
    
	GLfloat *oscilLine_ptr;
	GLfloat max = drawBufferLen;
	SInt8 *drawBuffer_ptr;
	
	// Alloc an array for our oscilloscope line vertices
	if (resetOscilLine) {
		oscilLine = (GLfloat*)realloc(oscilLine, drawBufferLen * 2 * sizeof(GLfloat));
		resetOscilLine = NO;
	}
	
	int drawBuffer_i;
	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
	{
		if (!drawBuffers[drawBuffer_i]) continue;
		
		oscilLine_ptr = oscilLine;
		drawBuffer_ptr = drawBuffers[drawBuffer_i];
		
		GLfloat i;
		// Fill our vertex array with points
        
        BOOL flagFound = NO;
        
		for (i=0.; i<max; i=i+1.)
		{
			*oscilLine_ptr++ = i/max;            
            
            for (int j=0; j<7; j++) {
                if (*drawBuffer_ptr>=1 && i>=FreqRate[j]-5 && i<=FreqRate[j]+5) {
                    flagFound = YES;
                    histroyRateIndex%=2;
                    histroyRate[histroyRateIndex] = j;
                    histroyRateIndex++;
                    NSLog(@"index %f = %d", i, *drawBuffer_ptr);
                    break;
                }
            }
            
            if (flagFound) {
                break;
            }
            
			*oscilLine_ptr++ = (Float32)(*drawBuffer_ptr++) / 128.;
		}
        
        if (!flagFound) {
            histroyRate[0] = -1;
            histroyRate[1] = -1;
            histroyRate[2] = -1;
            histroyRateIndex = 0;
        }
        
        if (histroyRateIndex==2) {
            NSLog(@"0=%d 1=%d 2=%d", histroyRate[0], histroyRate[1], histroyRate[2]);
            if (histroyRate[0]==histroyRate[1] /* && histroyRate[1]==histroyRate[2] */ && histroyRate[0]!=-1) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kFrequencyReceievedNotification" object:nil];
            }
            histroyRateIndex = 0;
        }
	}
}



# pragma mark-



- (void)dealloc
{	
    delete[] dcFilter;
	delete fftBufferManager;
	free(oscilLine);
    
    [super dealloc];
}

@end
