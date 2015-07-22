//
//  AppDelegate.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/23/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "AppDelegate.h"

// Helpers
#import "SBSystemPreferences.h"

// Views
#import "FJCPreferencesPanel.h"

// Controllers
#include "KBLKeyboardBacklightService.h"
#include "FJCLuciferController.h"

// Categories
#import "NSArray+FMTNSArrayFunctional.h"


// Keys
static NSString *const kAppDidRunBefore = @"kAppDidRunBefore";


@interface AppDelegate ()

@property (weak) IBOutlet FJCPreferencesPanel *preferencesPanel;

@property (nonatomic, strong) NSStatusItem *statusItem;

// Outlets
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *toggleStatusMenuItem;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Keyboard.prefPane"];
    
    [self _checkSystemAuthorization];
    [self _showAlertIfFirstTimeOpeningTheApp];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.menu = self.menu;
    
    [self didPressToggleEnabled:self.toggleStatusMenuItem];
    
    // Register global hotkey for enable/disable
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event) {
        if ((event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask) &&
            event.keyCode == 37)
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
        
        self.statusItem.image = [NSImage imageNamed:@"statusItemIcon_Off"];
    }
    else if ([lu startMonitor])
    {
        sender.title = @"Disable";
        
        self.statusItem.image = [NSImage imageNamed:@"statusItemIcon_On"];
    }
}


- (IBAction)didPressQuitItem:(NSMenuItem *)sender
{
    [NSApp terminate:nil];
}

#pragma mark - Private Methods

- (void)_checkSystemAuthorization
{
    if (!AXIsProcessTrusted())
    {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Authorization Required";
        alert.informativeText = @"Lucifer needs to be authorized to use an Accessibility Services in order to be able to move and resize application windows.\n\nYou can do this in System Preferences > Security & Privacy > Privacy > Accessibility. You might need to drag-and-drop ShiftIt into the list of allowed apps and make sure the checkbox is on.";
        
        [alert addButtonWithTitle:@"Open System Preferences"];
        [alert addButtonWithTitle:@"Recheck"];
        [alert addButtonWithTitle:@"Quit"];
        
        NSImageView *accessory = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 300, 234)];
        [accessory setImage:[NSImage imageNamed:@"keyboardPrefPane"]];
        [accessory setImageFrameStyle:NSImageFrameGrayBezel];
        [alert setAccessoryView:accessory];
        
        BOOL recheck = true;
        while (recheck)
        {
            NSModalResponse response = [alert runModal];
            switch (response)
            {
                case NSAlertFirstButtonReturn:
                {
                    NSString *key = (__bridge NSString *) kAXTrustedCheckOptionPrompt;
                    CFDictionaryRef options = (__bridge CFDictionaryRef) @{key: @NO};
                    AXIsProcessTrustedWithOptions((CFDictionaryRef) options);
                    
                    SBSystemPreferencesApplication *prefs = [SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
                    [prefs activate];
                    
                    SBSystemPreferencesPane *pane = [[prefs panes] find:^BOOL(SBSystemPreferencesPane *elem) {
                        return [[elem id] isEqualToString:@"com.apple.preference.security"];
                    }];
                    SBSystemPreferencesAnchor *anchor = [[pane anchors] find:^BOOL(SBSystemPreferencesAnchor *elem) {
                        return [[elem name] isEqualToString:@"Privacy_Accessibility"];
                    }];
                    
                    [anchor reveal];
                }
                    
                    break;
                case NSAlertSecondButtonReturn:
                    recheck = !AXIsProcessTrusted();
                    
                    break;
                case NSAlertThirdButtonReturn:
                    [NSApp terminate:self];
                    
                    break;
                default:
                    DLog(@"Alert Response: %ld", response);
            }
            
        }
    }
}

- (void)_showAlertIfFirstTimeOpeningTheApp
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kAppDidRunBefore])
    {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Keyboard Settings";
        alert.informativeText = @"Lucifer needs you to disable \"Adjust keyboard brightness in low light\" in order to function properly. If your keyboard keeps changing its brightness automatically, Lu may be confused.\n\nYou can do this in System Prefences > Keyboard > General. You may also need to set the \"Turn off when computer is not used\" slider to \"Never\".";
        
        [alert addButtonWithTitle:@"Open System Preferences"];
        [alert addButtonWithTitle:@"Close"];
        
        NSImageView *accessory = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 400, 350)];
        [accessory setImage:[NSImage imageNamed:@"keyboardPrefPane"]];
        [accessory setImageFrameStyle:NSImageFrameGrayBezel];
        [alert setAccessoryView:accessory];
        
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            SBSystemPreferencesApplication *prefs = [SBApplication applicationWithBundleIdentifier:@"com.apple.systempreferences"];
            [prefs activate];
            
            SBSystemPreferencesPane *pane = [[prefs panes] find:^BOOL(SBSystemPreferencesPane *elem) {
                return [[elem id] isEqualToString:@"com.apple.preference.keyboard"];
            }];
            
            SBSystemPreferencesAnchor *anchor = [[pane anchors] find:^BOOL(SBSystemPreferencesAnchor *elem) {
                return [[elem name] isEqualToString:@"keyboardTab"];
            }];
            
            [anchor reveal];
        }
    }
    
    [userDefaults setBool:YES forKey:kAppDidRunBefore];
    [userDefaults synchronize];
}

@end
