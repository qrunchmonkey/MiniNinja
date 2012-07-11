//
//  NinjaAVFoundationExporter.h
//  ScreenNinja
//
//  Created by Kris Harris on 3/10/12.
//  Copyright (c) 2012 Improbable Sciences. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@interface NinjaAVFoundationExporter : NSObject {
    

}
- (id)initWithDestinationFilePath:(NSString*)destinationPath captureRect:(CGRect)rect expectDataInRealTime:(BOOL)realTime;

- (void)addFrameFromCGImage:(CGImageRef)buffer;
- (void)doneExporting;

@end
