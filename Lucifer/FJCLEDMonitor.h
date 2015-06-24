//
//  FJCLEDMonitor.h
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const kFJCLEDMonitorDidUpdateValue;


@interface FJCLEDMonitor : NSObject

+ (instancetype)sharedMonitor;

- (BOOL)startMonitoring;
- (BOOL)stopMonitoring;

@end
