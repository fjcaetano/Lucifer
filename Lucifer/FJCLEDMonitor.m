//
//  FJCLEDMonitor.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "FJCLEDMonitor.h"

// Controllers
#import "KBLKeyboardBacklightService.h"


static const NSTimeInterval kTimerTimeInterval = 1;
NSString *const kFJCLEDMonitorDidUpdateValue = @"kFJCLEDMonitorDidUpdateValue";
static dispatch_queue_t _FJCLEDMonitorQueue = NULL;


@interface FJCLEDMonitor ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, readwrite) uint64_t previousLEDValue;

@end


@implementation FJCLEDMonitor

- (instancetype)initSuper
{
    if (self = [super init])
    {
        KBLStartLightService();
        _FJCLEDMonitorQueue = dispatch_queue_create("com.flaviocaetano.FJCLEDMonitor", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)sharedMonitor
{
    static FJCLEDMonitor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FJCLEDMonitor alloc] initSuper];
    });
    
    return sharedInstance;
}

- (BOOL)startMonitoring
{
    if (self.timer == nil)
    {
        dispatch_async(_FJCLEDMonitorQueue, ^{
            self.timer = [NSTimer timerWithTimeInterval:kTimerTimeInterval
                                                 target:self
                                               selector:@selector(_didFireTimer)
                                               userInfo:nil
                                                repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] run];
        });
        
        DLog(@"Started KBL monitor");
        
        return YES;
    }
    
    return NO;
}

- (BOOL)stopMonitoring
{
    if (self.timer != nil)
    {
        [self.timer invalidate], self.timer = nil;
        
        DLog(@"Stopped KBL monitor");
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Private Methods

- (void)_didFireTimer
{
//    DLog(@"Did loop KBL monitor");
    uint64_t LEDValue = KBLGetKeyboardLEDValue();
    
    if (LEDValue != self.previousLEDValue)
    {
        DLog(@"Did update KBL value");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kFJCLEDMonitorDidUpdateValue object:@(LEDValue)];
    }
    
    self.previousLEDValue = LEDValue;
}

@end
