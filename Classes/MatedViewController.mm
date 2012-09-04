//
//  InstructionForMateViewController.m
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-3.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import "MatedViewController.h"
#import "FrequencyReceiver.h"
#import "FrequencySender.h"
#import "aurioTouchAppDelegate.h"

static BOOL arrShake[10];


static BOOL L0AccelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
	double
	deltaX = fabs(last.x - current.x),
	deltaY = fabs(last.y - current.y),
	deltaZ = fabs(last.z - current.z);
	
	return
	(deltaX > threshold && deltaY > threshold) ||
	(deltaX > threshold && deltaZ > threshold) ||
	(deltaY > threshold && deltaZ > threshold);
}




@implementation MatedViewController
@synthesize lastAcceleration;


- (IBAction)pressBack:(id)button
{   
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [receiver stopTrack];
    [sender stopTone];
    [UIAccelerometer sharedAccelerometer].delegate = nil;       
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    [timerNextStep invalidate];
    [timerNextStep release], timerNextStep = nil;    
    [aurioTouchAppDelegate changeAppState:AppResearching animated:YES];
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
    
    if (state!=InstructionStateCheckShake) {
        return;
    }
	
    //	if (self.lastAcceleration) {
    //        if (L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
    //            histeresisExcited = YES;
    //        }
    //        else {
    //            histeresisExcited = NO;
    //        }
    //	}
    
    
    
    if (self.lastAcceleration) {
		if (!histeresisExcited && L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
			histeresisExcited = YES;
		} else if (histeresisExcited && !L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.2)) {
			histeresisExcited = NO;
		}
	}
	
	self.lastAcceleration = acceleration;
    
//    NSLog(@"his = %d", histeresisExcited);
    

    
    static int count = 0;
    static int lastCount = 0;
    
    arrShake[count] = histeresisExcited;
    
    int isStop = YES;
    for (int i=0; i<10; i++) {
        if (arrShake[i]) {
            isStop = NO;
        }
    }
    
    if (isStop) {
        if (count!=0) {
            NSLog(@"count = %d", count);    
            if (count>=3) {
                shakingTimes++;
                if (shakingTimes>=SHAKING_TIMES) {
                    [sender playTone:21000];
                    state = InstructionStateDone;
                    [self nextStep];
                }
            }
        }
        
        count = 0;
        lastCount = 0;
    }
    else{
        count++;
        count = count%10;        
    }
    
    if (histeresisExcited) {        
        lastCount++;        
    }
}


- (void)nextStep
{
    static int count = 0;
    static int countMax = -1;
    static int indexFreq = -1;
    
    if (countMax==-1) {
        countMax = ABS(arc4random())%10+10;
    }
    if (indexFreq==-1) {
        indexFreq = ABS(arc4random())%4;
    }
    
    switch (state) {
        case InstructionStateReady:   
            break;
        case InstructionStateCheckShake: 
            break;
        case InstructionStateDone:
//            if (![receiver isTracking]) {
//                [receiver startTrack];
//            }
            break;
    }
}

- (void)receivedFrequency
{
    if (state==InstructionStateReady) {
        
    }
    else if (state==InstructionStateDone || state==InstructionStateCheckShake) {
        if (histroyRate[0]==6){
            [[NSNotificationCenter defaultCenter] removeObserver:self];            
            [aurioTouchAppDelegate changeAppState:AppGame animated:YES];
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)hiddenSound{
    if ([sender isPlaying]) {
        [sender stopTone]; 
    }
    [receiver startTrack];
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated
{
    shakingTimes = 0;

    [UIAccelerometer sharedAccelerometer].delegate = self;    
    state = InstructionStateCheckShake;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFrequency)
                                                 name:@"kFrequencyReceievedNotification" 
                                               object:nil];
    
    [timerNextStep invalidate];
    [timerNextStep release];
    timerNextStep = [[NSTimer scheduledTimerWithTimeInterval:1/10.f target:self selector:@selector(nextStep) userInfo:nil repeats:YES] retain];
    
    [sender playTone:freq[4]];
    
    [self performSelector:@selector(hiddenSound) withObject:nil afterDelay:10.f];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [timerNextStep invalidate];
    [timerNextStep release], timerNextStep = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [UIAccelerometer sharedAccelerometer].delegate = nil;   
    [receiver stopTrack];
    [sender stopTone];
}




- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];   
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
