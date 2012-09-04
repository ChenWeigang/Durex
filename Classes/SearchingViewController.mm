//
//  RearchingViewController.m
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-3.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import "SearchingViewController.h"
#import "VPUtil.h"
#import "FrequencyReceiver.h"
#import "FrequencySender.h"
#import "aurioTouchAppDelegate.h"


double freq[7] = {18000,18500,19000,19500,20000,20500,21000};
//int FreqRate[7] = {835, 858, 881, 905, 928, 951, 974};
static int count = 0;
static int countMax = 0;
static int indexFreq = 0;

@interface SearchingViewController ()

@end

@implementation SearchingViewController




- (void)receivedFrequency
{
    NSLog(@"received frequency %d", histroyRate[0]);
    
    if (state==SearchStateSearchReceieving) {
        if (histroyRate[0]>=0 && histroyRate[0]<=3) {
            [receiver stopTrack];
            [sender stopTone];
            state = SearchStateMatching0;
        }
        else if (histroyRate[0]==4 || histroyRate[0]==5){
            state = SearchStateMatching1;
        }
        [self nextStep];
    }
    else if (state==SearchStateSearchSending) {
        if (histroyRate[0]==4 || histroyRate[0]==5){
            state = SearchStateMatching1;
            [self nextStep];
        }
    }
}


- (void)nextStep
{

    
    if (state!=lastState) {
        count = 0;
    }
    
    switch (state) {
        case SearchStateInit:       
            break;
        case SearchStateSearchReceieving: 
            labMate.text = @"Receieving";
            if ([sender isPlaying]) {                
                [sender stopTone];
            }
            if (![receiver isTracking]) {
                [receiver startTrack]; 
            }
                   
            if (count%countMax==countMax-1) {
                state = SearchStateSearchSending;
            }          
            break;
        case SearchStateSearchSending:
        {
            labMate.text = @"Sending";
            if ([receiver isTracking]) {
                [receiver stopTrack];
            }
//            float f = 20000;
            if (![sender isPlaying]) {
//                [sender playTone:f];
//                NSLog(@"play tone %f", f);
                                [sender playTone:freq[indexFreq]];
                                NSLog(@"play tone = %f", freq[indexFreq]);
                                labTitle.text = [NSString stringWithFormat:@"%f", freq[indexFreq]];
                                indexFreq++;
                                indexFreq = indexFreq%4;
            }
            if (count%countMax==countMax-1) {
                state = SearchStateSearchReceieving;
            }
        }
            break;
        case SearchStateMatching0:
            if (![receiver isTracking]) {
                [receiver startTrack];
            }
            if (![sender isPlaying]) {
                [sender playTone:freq[4]];
                labTitle.text = [NSString stringWithFormat:@"%f", freq[indexFreq]];
                NSLog(@"play tone = %f", freq[indexFreq]);
            }
            NSLog(@"play tone = %f", freq[indexFreq]);
            labMate.text = @"Matching0";
            
            state = SearchStateMated;
            [self performSelector:@selector(go2Mated) withObject:nil afterDelay:2.0f];
            
            break;
        case SearchStateMatching1:
            if (![receiver isTracking]) {
                [receiver startTrack];
            }
            if (![sender isPlaying]) {
                [sender playTone:freq[5]];
                NSLog(@"play tone = %f", freq[indexFreq]);
            }
            labMate.text = @"Matching1";            
            state = SearchStateMated;
            [self performSelector:@selector(go2Mated) withObject:nil afterDelay:0.5f];
            break;
        case SearchStateMated:
        default:
            break;
    }
//    NSLog(@"state = %d", state);
    lastState = state;
    count++;
}

- (void)go2Mated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [timerNextStep invalidate];
    [timerNextStep release], timerNextStep = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [aurioTouchAppDelegate changeAppState:AppMateInstruction animated:YES];
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
    
    lastState = SearchStateInit;    
}


- (void)viewDidAppear:(BOOL)animated
{
    [receiver stopTrack];
    [sender stopTone];
    
    state = SearchStateSearchReceieving;
    count = 0;
    countMax = ABS(arc4random())%10+10;
    indexFreq = ABS(arc4random())%4;
    histroyRate[0] = -1;
    histroyRate[1] = -1;
    histroyRate[2] = -1;
    histroyRateIndex = 0;
    
    [timerNextStep invalidate];
    [timerNextStep release], timerNextStep = nil;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFrequency)
                                                 name:@"kFrequencyReceievedNotification" 
                                               object:nil];
    
    timerNextStep = [[NSTimer scheduledTimerWithTimeInterval:1/10.f target:self selector:@selector(nextStep) userInfo:nil repeats:YES] retain];  

    CGRect frame = viewLoading.frame;
    frame.size.width = 1;
    viewLoading.frame = frame;
    NSLog(@"%@", NSStringFromCGRect(viewLoading.frame));
    
    [UIView animateWithDuration:40 
                          delay:0 
                        options:UIViewAnimationOptionCurveLinear 
                     animations:^{
                         CGRect frame1 = viewLoading.frame;
                         frame1.size.width = 181;
                         viewLoading.frame = frame1;
    } completion:^(BOOL finished) {                
        if (finished) {
            state = SearchStateInit;
            
            if ([receiver isTracking]) {
                [receiver stopTrack];
            }
            if ([sender isPlaying]) {
                [sender stopTone];
            }
            
            [timerNextStep invalidate];
            [timerNextStep release], timerNextStep = nil;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            

            
            [aurioTouchAppDelegate changeAppState:AppResearchFailed animated:YES];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([receiver isTracking]) {
        [receiver stopTrack];
    }
//    if ([sender isPlaying]) {
//        [sender stopTone];
//    }
    
    [timerNextStep invalidate];
    [timerNextStep release], timerNextStep = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view.layer removeAllAnimations];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
