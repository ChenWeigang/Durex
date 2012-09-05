//
//  GameViewController.m
//  aurioTouch
//
//  Created by Chen Weigang on 12-8-3.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import "GameViewController.h"
#import "aurioTouchAppDelegate.h"
#import "FrequencyReceiver.h"
#import "FrequencySender.h"

@interface GameViewController ()

@end

@implementation GameViewController


- (IBAction)pressOk
{
    NSLog(@"OK");
    [aurioTouchAppDelegate changeAppState:AppResearching animated:YES];
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
    [self performSelector:@selector(hiddenSound) withObject:nil afterDelay:5.f];
}

- (void)hiddenSound{
    if ([sender isPlaying]) {
        [sender stopTone]; 
    }
    if ([receiver isTracking]) {
        [receiver stopTrack];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self hiddenSound];
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
