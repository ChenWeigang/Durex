//
//  RearchingViewController.h
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-3.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class FrequencyReceiver;
@class FrequencySender;
extern FrequencyReceiver *receiver;
extern FrequencySender *sender;
extern double freq[7];

typedef enum {
    SearchStateInit = 0,
    SearchStateSearchSending,
    SearchStateSearchReceieving,
    SearchStateMatching0,
    SearchStateMatching1,
    SearchStateMated,
}SearchState;

extern int FreqRate[7];
extern int histroyRate[3];
extern int histroyRateIndex;

@interface SearchingViewController : UIViewController {

    SearchState state;
    SearchState lastState;
    NSTimer *timerNextStep;
    
    IBOutlet UILabel *labTitle;
    IBOutlet UILabel *labMate;
    IBOutlet UIView *viewLoading;
    
    int count;
    int countMax;
    int indexFreq;
}


@end
