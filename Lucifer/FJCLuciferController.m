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


static uint64_t const kLEDDimmingDuration = 1000;
static NSTimeInterval const kDefaultTimeoutToBlackout = 60*5;


@interface FJCLuciferController ()

@property (nonatomic, strong) id keyboardEventMonitor;
@property (nonatomic, strong) id mouseEventMonitor;

@property (nonatomic, readwrite) BOOL isKeyboardLit;
@property (nonatomic, readwrite) uint64_t keyboardLEDPreviousValue;

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation FJCLuciferController

- (instancetype)initSuper
{
    if (self = [super init])
    {
        self.blackList = [NSMutableArray new];
        self.timeOutToBlackout = kDefaultTimeoutToBlackout;
        self.monitorType = FJCLuciferMonitorTypeKeyboard;
        
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

- (void)startMonitor
{
    if (self.monitorType & FJCLuciferMonitorTypeMouse)
    {
        [self _startCursorMonitor];
    }
    
    if (self.monitorType & FJCLuciferMonitorTypeKeyboard)
    {
        [self _startKeyboardMonitor];
    }
}

- (void)stopMonitor
{
    [[FJCLEDMonitor sharedMonitor] stopMonitoring];
    
    [NSEvent removeMonitor:self.keyboardEventMonitor];
    [NSEvent removeMonitor:self.mouseEventMonitor];
}

#pragma mark - Notifications

- (void)_didUpdateKBLValue:(NSNotification *)notification
{
    uint64_t kblValue = [notification.object unsignedLongLongValue];
    self.isKeyboardLit = (kblValue > 100);
    
    // Checking whether or not the keyboard was lit using hardware keys (F5, F6)
    if (self.isKeyboardLit)
    {
        [self _setupTimer];
    }
}

#pragma mark - Private Methods

- (void)_startKeyboardMonitor
{
    KBLStartLightService();
    
    [[FJCLEDMonitor sharedMonitor] startMonitoring];
    
    self.keyboardEventMonitor =
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask|NSFlagsChangedMask)
                                           handler:^(NSEvent *event) {
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
    KBLStartLightService();
    
    [[FJCLEDMonitor sharedMonitor] startMonitoring];
    
    self.mouseEventMonitor =
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSMouseMovedMask|NSScrollWheelMask|NSLeftMouseDownMask|NSRightMouseDownMask)
                                           handler:^(NSEvent *event) {
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
    [self.timer invalidate], self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeOutToBlackout
                                                  target:self
                                                selector:@selector(_timerDidFire)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)_timerDidFire
{
    // Stores the previous light power before turning it off
    self.keyboardLEDPreviousValue = KBLGetKeyboardLEDValue();
    KBLSetKeyboardLEDValueFade(0, kLEDDimmingDuration);
}

@end
