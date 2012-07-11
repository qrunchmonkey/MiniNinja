//
//  ISSAppDelegate.m
//  MiniNinja
//
//  Created by Kris Harris on 6/14/12.
//  Copyright (c) 2012 ImprobableSciences. All rights reserved.
//

#import "ISSAppDelegate.h"

@implementation ISSAppDelegate
@synthesize realTimeCheckBox;
@synthesize recordButton;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)recordPressed:(id)sender {
    if (self.autoRecordTimer) return;
    
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];

    NSString *suggestedFileName = @"Screen Recording";
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"mov"]];
    [savePanel setNameFieldStringValue:[suggestedFileName stringByAppendingPathExtension:@"mov"]];


    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setMessage:@"Screen recording destination"];
    
    [savePanel beginSheetModalForWindow:self.window
                      completionHandler:^(NSInteger result) {
                          if (result) {
                              NSString *path = [[savePanel URL] path];
                              if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                                  [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
                              }
                              [self beginRecordingToPath:path];
                          }

                      }];
    
    }

- (void)beginRecordingToPath:(NSString *)path {
    
    [self.recordButton setEnabled:NO];
    [self.realTimeCheckBox setEnabled:NO];
    [self.recordButton setTitle:@"Recording…"];
    
    BOOL realTime = [self.realTimeCheckBox state] == NSOnState;
    
    self.exporter = [[[NinjaAVFoundationExporter alloc] initWithDestinationFilePath:path
                                                                       captureRect:[[NSScreen mainScreen] frame] expectDataInRealTime:realTime] autorelease];
    
    self.autoRecordTimer = [NSTimer scheduledTimerWithTimeInterval:60 /* Recording time in seconds */
                                                            target:self
                                                          selector:@selector(stopRecording:)
                                                          userInfo:nil
                                                           repeats:NO];
    
    self.frameTimer = [NSTimer scheduledTimerWithTimeInterval:1 /*frame interval in seconds */
                                                       target:self
                                                     selector:@selector(captureFrame:)
                                                     userInfo:nil
                                                      repeats:YES];

    
}


- (void)stopRecording:(id)sender {
    [self.frameTimer invalidate];
    self.frameTimer = nil;
    
    [self.autoRecordTimer invalidate];
    self.autoRecordTimer = nil;
    
    
    [self.exporter doneExporting];
    
    self.exporter = nil;
    
    [self.recordButton setEnabled:YES];
    [self.realTimeCheckBox setEnabled:YES];
    
    [self.recordButton setTitle:@"Record"];

}

- (void)captureFrame:(id)sender {
    CGImageRef screenshot = CGWindowListCreateImage([[NSScreen mainScreen] frame],
                                                    kCGWindowListOptionAll,
                                                    kCGNullWindowID,
                                                    kCGWindowImageDefault);
    
    [self.exporter addFrameFromCGImage:screenshot];

    CGImageRelease(screenshot);
}


@end
