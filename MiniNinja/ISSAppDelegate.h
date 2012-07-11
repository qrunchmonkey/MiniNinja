//
//  ISSAppDelegate.h
//  MiniNinja
//
//  Created by Kris Harris on 6/14/12.
//  Copyright (c) 2012 ImprobableSciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NinjaAVFoundationExporter.h"

@interface ISSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *realTimeCheckBox;
@property (assign) IBOutlet NSButton *recordButton;

@property (nonatomic, strong) NSTimer *autoRecordTimer;
@property (nonatomic, strong) NSTimer *frameTimer;

@property (nonatomic, strong) NinjaAVFoundationExporter *exporter;

- (IBAction)recordPressed:(id)sender;
- (void)beginRecordingToPath:(NSString*)path;

@end
