//
//  FJCLuciferController.h
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(short, FJCLuciferMonitorType)
{
    FJCLuciferMonitorTypeKeyboard = 1 << 0,
    FJCLuciferMonitorTypeMouse = 1 << 1
};


@interface FJCLuciferController : NSObject

@property (nonatomic, readwrite) FJCLuciferMonitorType monitorType;

@property (nonatomic, strong) NSMutableArray *blackList;
@property (nonatomic, readwrite) NSTimeInterval timeOutToBlackout;


#pragma mark - Methods

+ (instancetype)sharedController;

- (void)startMonitor;
- (void)stopMonitor;

@end
