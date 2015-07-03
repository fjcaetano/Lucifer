//
//  FJCLuciferController.h
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_OPTIONS(short, FJCLuciferMonitorType)
{
    FJCLuciferMonitorTypeKeyboard = 1 << 0,
    FJCLuciferMonitorTypeMouse = 1 << 1
};


@interface FJCLuciferController : NSObject

@property (nonatomic, readwrite) FJCLuciferMonitorType monitorType;

@property (nonatomic, readonly) NSArray *blackList;
@property (nonatomic, readwrite) NSTimeInterval timeOutToBlackout;

@property (nonatomic, readonly) BOOL isMonitoring;


#pragma mark - Methods

+ (instancetype)sharedController;

- (BOOL)startMonitor;
- (void)stopMonitor;

- (void)addKeyToBlacklist:(id)keyCode;
- (void)removeItemsAtIndexesFromBlackList:(NSIndexSet *)indexSet;

@end
