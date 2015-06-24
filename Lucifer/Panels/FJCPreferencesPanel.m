//
//  FJCPreferencesPanel.m
//  Lucifer
//
//  Created by Flávio Caetano on 6/24/15.
//  Copyright (c) 2015 Shufflow. All rights reserved.
//

#import "FJCPreferencesPanel.h"

// Controllers
#import "FJCLuciferController.h"


@interface FJCPreferencesPanel ()

@property (weak) IBOutlet NSButton *monitorKeyboardButton;
@property (weak) IBOutlet NSButton *monitorMouseButton;

@property (weak) IBOutlet NSTextField *selectedTimeLabel;
@property (weak) IBOutlet NSSlider *timeoutSlider;

@end


@implementation FJCPreferencesPanel

- (void)makeKeyAndOrderFront:(id)sender
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    self.monitorMouseButton.state = (lu.monitorType & FJCLuciferMonitorTypeMouse);
    self.monitorKeyboardButton.state = (lu.monitorType & FJCLuciferMonitorTypeKeyboard);
    
    int timeOutInMinutes = (lu.timeOutToBlackout / 60);
    self.timeoutSlider.integerValue = timeOutInMinutes;
    self.selectedTimeLabel.stringValue = [NSString stringWithFormat:@"%d minutes", timeOutInMinutes];
    
    [super makeKeyAndOrderFront:sender];
}

- (IBAction)didChangeSliderValue:(NSSlider *)sender
{
    self.selectedTimeLabel.stringValue = [NSString stringWithFormat:@"%ld minutes", sender.integerValue];
    
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    lu.timeOutToBlackout = sender.integerValue * 60;
    
    [lu stopMonitor];
    [lu startMonitor];
}

- (IBAction)didPressMonitorKeyboardButton:(NSButton *)sender
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    lu.monitorType ^= FJCLuciferMonitorTypeKeyboard;
    
    [lu stopMonitor];
    [lu startMonitor];
}

- (IBAction)didPressMonitorMouseButton:(NSButton *)sender
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    lu.monitorType ^= FJCLuciferMonitorTypeMouse;
    
    [lu stopMonitor];
    [lu startMonitor];
}


@end
