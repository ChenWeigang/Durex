//
//  Frequency.m
//  aurioTouch
//
//  Created by Chen Weigang on 12-9-5.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import "Frequency.h"
// 18k ~ 21k
double freq[7] = {18000, 18500, 19000, 19500, 20000, 20500, 21000};
int FreqRate[7] = {835, 858, 881, 905, 928, 951, 974};
int histroyRate[3] = {-1,-1,-1};
int histroyRateIndex = 0;
