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

// Identifiers
static NSString *const kCode = @"kCode";
static NSString *const kKeystroke = @"kKeystroke";


@interface FJCPreferencesPanel () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, readwrite) BOOL isAddingElementToBlacklist;

@property (nonatomic, weak) id keyCaptureMonitor;

// General Tab
@property (weak) IBOutlet NSButton *monitorKeyboardButton;
@property (weak) IBOutlet NSButton *monitorMouseButton;

@property (weak) IBOutlet NSTextField *selectedTimeLabel;
@property (weak) IBOutlet NSSlider *timeoutSlider;

// Blacklist Tab
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSSegmentedControl *segmentedControl;

// About Tab
@property (weak) IBOutlet NSTextField *versionLabel;
@property (weak) IBOutlet NSTextField *releaseDateLabel;

@end


@implementation FJCPreferencesPanel

- (void)makeKeyAndOrderFront:(id)sender
{
    // General Tab
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    self.monitorMouseButton.state = (lu.monitorType & FJCLuciferMonitorTypeMouse);
    self.monitorKeyboardButton.state = (lu.monitorType & FJCLuciferMonitorTypeKeyboard);
    
    int timeOutInMinutes = (lu.timeOutToBlackout / 60);
    self.timeoutSlider.integerValue = timeOutInMinutes;
    self.selectedTimeLabel.stringValue = [NSString stringWithFormat:@"%d minutes", timeOutInMinutes];
    
    
    // Blacklist Tab
    [self.tableView reloadData];
    
    
    // About Tab
    NSBundle *bundle = [NSBundle mainBundle];
    self.releaseDateLabel.stringValue = [bundle objectForInfoDictionaryKey:@"BTBuildDate"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"%@ (%@)",
                                     [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                     [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    
    [NSApp activateIgnoringOtherApps:YES];
    [super makeKeyAndOrderFront:sender];
}

#pragma mark Properties

- (void)setIsAddingElementToBlacklist:(BOOL)isAddingElementToBlacklist
{
    _isAddingElementToBlacklist = isAddingElementToBlacklist;
    
    [self.segmentedControl setEnabled:!isAddingElementToBlacklist forSegment:0];
    
    if (!isAddingElementToBlacklist)
    {
        [NSEvent removeMonitor:self.keyCaptureMonitor];
    }
}

#pragma mark - UI Actions

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

- (IBAction)didPressTableViewActions:(NSSegmentedControl *)sender
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    
    switch (sender.selectedSegment)
    {
        case 0:
        {
            self.isAddingElementToBlacklist = YES;
            
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lu.blackList.count];
            
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationSlideDown];
            [self.tableView endUpdates];
            
            [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
        }
            break;
            
        case 1:
            [lu removeItemsAtIndexesFromBlackList:self.tableView.selectedRowIndexes];
            
            [self.tableView beginUpdates];
            [self.tableView removeRowsAtIndexes:self.tableView.selectedRowIndexes withAnimation:NSTableViewAnimationSlideUp];
            [self.tableView endUpdates];
            
        default:
            break;
    }
}

- (IBAction)didSelectRowOnTableView:(NSTableView *)sender
{
    BOOL hasRowsSelected = (sender.selectedRowIndexes.count > 0);
    
    if (!hasRowsSelected)
    {
        self.isAddingElementToBlacklist = NO;
        
        [self.tableView reloadData];
        
    }
    
    [self.segmentedControl setEnabled:hasRowsSelected forSegment:1];
}

- (IBAction)didPressGithubButton:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/fjcaetano/Lucifer"]];
}

#pragma mark - Table View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    return lu.blackList.count + self.isAddingElementToBlacklist;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    FJCLuciferController *lu = [FJCLuciferController sharedController];
    NSString *result = @"";
    
    if (row < lu.blackList.count)
    {
        result = [lu.blackList[row] description];
    }
    
    if ([tableColumn.identifier isEqualToString:kCode])
    {
        NSTableCellView *cell = (NSTableCellView *)view;
        cell.textField.stringValue = result;
    }
    else if ([tableColumn.identifier isEqualToString:kKeystroke])
    {
        NSTextField *textField = (NSTextField *)view;
        
        if (self.isAddingElementToBlacklist)
        {
            textField.editable = YES;
            [self _setupCaptureKeyEvent];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0625 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [textField becomeFirstResponder];
            });
        }
        else
        {
            textField.editable = NO;
            result = [self keyCodeMap][result];
        }
        
        textField.stringValue = result;
    }
    
    return view;
}

#pragma mark - Private Methods

- (NSDictionary *)keyCodeMap
{
    static NSDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"KeyMapping" ofType:@"plist"];
        dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    });
    
    return dict;
}

- (void)_setupCaptureKeyEvent
{
    [NSEvent removeMonitor:self.keyCaptureMonitor];
    self.keyCaptureMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSKeyDownMask | NSFlagsChangedMask)
                                                                   handler:^NSEvent *(NSEvent *event) {
                                                                       FJCLuciferController *lu = [FJCLuciferController sharedController];
                                                                       
                                                                       if (![lu.blackList containsObject:@(event.keyCode)])
                                                                       {
                                                                           [lu addKeyToBlacklist:@(event.keyCode)];
                                                                       }
                                                                       
                                                                       self.isAddingElementToBlacklist = NO;
                                                                       [self.tableView reloadData];
                                                                       
                                                                       return nil;
                                                                   }];
}

@end
