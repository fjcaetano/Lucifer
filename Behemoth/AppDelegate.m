//
//  AppDelegate.m
//  Behemoth
//
//  Created by Flávio Caetano on 7/22/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    // This string takes you from MyGreat.App/Contents/Library/LoginItems/MyHelper.app to MyGreat.App This is an obnoxious but dynamic way to do this since that specific Subpath is required
    NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath]; // This gets the binary executable within your main application
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
    [NSApp terminate:nil];
}

@end
