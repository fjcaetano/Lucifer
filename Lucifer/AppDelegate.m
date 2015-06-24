//
//  AppDelegate.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/23/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "AppDelegate.h"

// Views
#import "FJCPreferencesPanel.h"

// Controllers
#include "KBLKeyboardBacklightService.h"
#include "FJCLuciferController.h"


@interface AppDelegate ()

@property (weak) IBOutlet FJCPreferencesPanel *preferencesPanel;

@property (nonatomic, strong) NSStatusItem *statusItem;

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *toggleStatusMenuItem;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"statusItemIcon"];
    self.statusItem.menu = self.menu;

    FJCLuciferController *lu = [FJCLuciferController sharedController];
    self.toggleStatusMenuItem.title = ([lu startMonitor] ? @"Disable" : @"Enable");
    
    // Register global hotkey for enable/disable
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event) {
        if (event.modifierFlags & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask) && event.keyCode == 37)
        {
            [self didPressToggleEnabled:self.toggleStatusMenuItem];
        }
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

#pragma mark - UI Actions

- (IBAction)didPressToggleEnabled:(NSMenuItem *)sender
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    if (lu.isMonitoring)
    {
        [lu stopMonitor];
        sender.title = @"Enable";
    }
    else if ([lu startMonitor])
    {
        sender.title = @"Disable";
    }
}


- (IBAction)didPressQuitItem:(NSMenuItem *)sender
{
    exit(0);
}

@end
