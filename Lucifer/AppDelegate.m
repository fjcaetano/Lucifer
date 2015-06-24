//
//  AppDelegate.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/23/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "AppDelegate.h"

// Controllers
#include "KBLKeyboardBacklightService.h"
#include "FJCLuciferController.h"


@interface AppDelegate ()
{
    CFRunLoopSourceRef downSourceRef;
}

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) id eventHandler;
@property (nonatomic, readwrite) uint64_t keyboardLightValue;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    lu.monitorType = (FJCLuciferMonitorTypeMouse | FJCLuciferMonitorTypeKeyboard);
    
    [lu startMonitor];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
