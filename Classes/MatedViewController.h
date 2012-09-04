//
//  InstructionForMateViewController.h
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-3.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    InstructionStateReady, // 看视频啊 设么的
    InstructionStateCheckShake,
    InstructionStateDone,
    
}InstructionState;

@class FrequencyReceiver;
@class FrequencySender;
extern FrequencyReceiver *receiver;
extern FrequencySender *sender;
extern int freq[7];

@interface MatedViewController : UIViewController <UIAccelerometerDelegate> {
    BOOL histeresisExcited;
    
    InstructionState state;
    NSTimer *timerNextStep;
    
    int shakingTimes;
}



@property(retain) UIAcceleration* lastAcceleration;

@end
