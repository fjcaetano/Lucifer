//
//  FJCLuciferController.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

@import Cocoa;


#import "FJCLuciferController.h"

// Controllers
#import "FJCLEDMonitor.h"
#import "KBLKeyboardBacklightService.h"

// Keys
static NSString *const kMonitorTypeUserDefaults = @"kMonitorTypeUserDefaults";
static NSString *const kTimeOutUserDefaults = @"kTimeOutUserDefaults";
static NSString *const kBlacklistUserDefaults = @"kBlacklistUserDefaults";


static uint64_t const kLEDDimmingDuration = 1000;
static NSTimeInterval const kDefaultTimeoutToBlackout = 60*5;


@interface FJCLuciferController ()

@property (nonatomic, strong) NSMutableArray *blackList;

@property (nonatomic, weak) id keyboardEventMonitor;
@property (nonatomic, weak) id mouseEventMonitor;

@property (nonatomic, readonly) BOOL isKeyboardLit;
@property (nonatomic, readwrite) uint64_t keyboardLEDPreviousValue;

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation FJCLuciferController

- (instancetype)initSuper
{
    if (self = [super init])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        self.blackList = [([userDefaults valueForKey:kBlacklistUserDefaults] ?: @[]) mutableCopy];
        self.timeOutToBlackout = ([userDefaults doubleForKey:kTimeOutUserDefaults] ?: kDefaultTimeoutToBlackout);
        self.monitorType = ([userDefaults integerForKey:kMonitorTypeUserDefaults] ?: FJCLuciferMonitorTypeKeyboard);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_didUpdateKBLValue:)
                                                     name:kFJCLEDMonitorDidUpdateValue
                                                   object:nil];
    }
    
    return self;
}

+ (instancetype)sharedController
{
    static FJCLuciferController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FJCLuciferController alloc] initSuper];
    });
    
    return sharedInstance;
}

#pragma mark - Properties

- (void)setMonitorType:(FJCLuciferMonitorType)monitorType
{
    _monitorType = monitorType;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _saveUserDefaults];
    });
}

- (void)setTimeOutToBlackout:(NSTimeInterval)timeOutToBlackout
{
    _timeOutToBlackout = timeOutToBlackout;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _saveUserDefaults];
    });
}

- (BOOL)isKeyboardLit
{
    return (KBLGetKeyboardLEDValue() > 100);
}

#pragma mark - Methods

- (BOOL)startMonitor
{
    NSString *key = (__bridge NSString *) kAXTrustedCheckOptionPrompt;
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{key: @YES};
    if (!AXIsProcessTrustedWithOptions(options)) return NO;
    
    if (self.monitorType & FJCLuciferMonitorTypeMouse)
    {
        [self _startCursorMonitor];
        _isMonitoring = YES;
    }
    
    if (self.monitorType & FJCLuciferMonitorTypeKeyboard)
    {
        [self _startKeyboardMonitor];
        _isMonitoring = YES;
    }
    
    DLog(@"Starting monitor: %d", self.isMonitoring);
    
    return self.isMonitoring;
}

- (void)stopMonitor
{
    DLog(@"Stopping monitor");
    
    [[FJCLEDMonitor sharedMonitor] stopMonitoring];
    [self.timer invalidate], self.timer = nil;
    
    [NSEvent removeMonitor:self.keyboardEventMonitor];
    [NSEvent removeMonitor:self.mouseEventMonitor];
    
    _isMonitoring = NO;
}

- (void)addKeyToBlacklist:(id)keyCode
{
    [(NSMutableArray *)self.blackList addObject:keyCode];
    
    [self _saveUserDefaults];
}

- (void)removeItemsAtIndexesFromBlackList:(NSIndexSet *)indexSet
{
    [(NSMutableArray *)self.blackList removeObjectsAtIndexes:indexSet];
    
    [self _saveUserDefaults];
}

#pragma mark - Notifications

- (void)_didUpdateKBLValue:(NSNotification *)notification
{
    // Checking whether or not the keyboard was lit using hardware keys (F5, F6)
    if (self.isKeyboardLit)
    {
        DLog(@"Handling BKL update");
        
        [self _setupTimer];
    }
}

#pragma mark - Private Methods

- (void)_startKeyboardMonitor
{
    if (self.keyboardEventMonitor) return;
    
    DLog(@"Starting keystrokes monitor");
    
    KBLStartLightService();
    [[FJCLEDMonitor sharedMonitor] startMonitoring];
    
    self.keyboardEventMonitor =
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask|NSFlagsChangedMask)
                                           handler:^(NSEvent *event) {
                                               NSString *chars = (event.type == NSKeyDown ? event.characters : nil);
                                               DLog(@"Did detect key: %d ('%@')", event.keyCode, chars);
                                               
                                               if (!self.isKeyboardLit)
                                               {
                                                   // Did stroke key with keyboard off
                                                   // Should lit it if the key is not blacklisted
                                                   if (![self.blackList containsObject:@(event.keyCode)])
                                                   {
                                                       KBLSetKeyboardLEDValueFade(self.keyboardLEDPreviousValue, kLEDDimmingDuration);
                                                   }
                                               }
                                               else
                                               {
                                                   // Did stroke key with keyboard lit
                                                   // Reset blackout timer
                                                   [self _setupTimer];
                                               }
                                           }];
    
    [self _setupTimer];
}

- (void)_startCursorMonitor
{
    if (self.mouseEventMonitor) return;
    
    DLog(@"Starting mouse movement monitor");
    
    KBLStartLightService();
    [[FJCLEDMonitor sharedMonitor] startMonitoring];
    
    self.mouseEventMonitor =
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSMouseMovedMask|NSScrollWheelMask|NSLeftMouseDownMask|NSRightMouseDownMask)
                                           handler:^(NSEvent *event) {
                                               DLog(@"Did detect move mouse");
                                               
                                               if (!self.isKeyboardLit)
                                               {
                                                   // Did mouse event with keyboard off
                                                   // Lit it immediately
                                                   KBLSetKeyboardLEDValueFade(self.keyboardLEDPreviousValue, kLEDDimmingDuration);
                                               }
                                               else
                                               {
                                                   // Did mouse event with keyboard on
                                                   // Reset blackout timer
                                                   [self _setupTimer];
                                               }
                                           }];
    
    [self _setupTimer];
}

- (void)_setupTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timer invalidate], self.timer = nil;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeOutToBlackout
                                                      target:self
                                                    selector:@selector(_timerDidFire)
                                                    userInfo:nil
                                                     repeats:NO];
    });
}

- (void)_timerDidFire
{
    // Stores the previous light power before turning it off
    self.keyboardLEDPreviousValue = (KBLGetKeyboardLEDValue() ?: self.keyboardLEDPreviousValue);
    
    DLog(@"Fading keyboard: %llu", self.keyboardLEDPreviousValue);
    
    KBLSetKeyboardLEDValueFade(0, kLEDDimmingDuration);
}

- (void)_saveUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:self.monitorType forKey:kMonitorTypeUserDefaults];
    [userDefaults setDouble:self.timeOutToBlackout forKey:kTimeOutUserDefaults];
    [userDefaults setValue:self.blackList forKey:kBlacklistUserDefaults];
    
    [userDefaults synchronize];
}

@end
