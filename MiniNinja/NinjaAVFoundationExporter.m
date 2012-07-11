//
//  NinjaAVFoundationExporter.m
//  ScreenNinja
//
//  Created by Kris Harris on 3/10/12.
//  Copyright (c) 2012 Improbable Sciences. All rights reserved.
//

#import "NinjaAVFoundationExporter.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>




@interface NinjaAVFoundationExporter() {
    CGRect captureRect;
    int frameNumber;
}

@property (nonatomic, retain) AVAssetWriter         *assetWriter;
@property (nonatomic, retain) AVAssetWriterInput    *assetWriterInput;
@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor *inputAdaptor;

@end


@implementation NinjaAVFoundationExporter

@synthesize assetWriter = _assetWriter;
@synthesize assetWriterInput = _assetWriterInput;
@synthesize inputAdaptor = _inputAdaptor;

- (id)initWithDestinationFilePath:(NSString*)destinationPath captureRect:(CGRect)rect expectDataInRealTime:(BOOL)realTime{
	if ( (self=[super init]) ) {
		
        
        
        captureRect = rect;
        
        float desiredBitrate = captureRect.size.width * captureRect.size.height * 20 /*fps*/;
        desiredBitrate /= 8000; //arbitrary
        desiredBitrate *= 1024; //in bps
        NSLog(@"desired bitrate: %f kbps", desiredBitrate/1024 );
        
        
        
        
        NSError *error;
        
        self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:destinationPath] fileType:AVFileTypeQuickTimeMovie error:&error];
        
        
        
        NSMutableDictionary * compressionProperties = [NSMutableDictionary dictionary];
        [compressionProperties setObject: [NSNumber numberWithInt: desiredBitrate]
                                  forKey: AVVideoAverageBitRateKey];

        
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey, /* If the codec is something other than AVVideoCodecH264, the issue does not occour*/
                                       [NSNumber numberWithInt:captureRect.size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:captureRect.size.height], AVVideoHeightKey,
                                       compressionProperties, AVVideoCompressionPropertiesKey,
                                       
                                       nil];
        
        self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                   outputSettings:videoSettings];
        [self.assetWriterInput setExpectsMediaDataInRealTime:realTime];
        
        [self.assetWriter addInput:_assetWriterInput];
        
        
        
        NSDictionary *pixelBufferSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
                                             [NSNumber numberWithInt:captureRect.size.width], kCVPixelBufferWidthKey,
                                             [NSNumber numberWithInt:captureRect.size.height], kCVPixelBufferHeightKey,

                                             nil];
        
        
        self.inputAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput 
                                                                                             sourcePixelBufferAttributes:pixelBufferSettings];
        
        
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:CMTimeMake(0, 600)];
        
    }
    return self;
}

- (void)dealloc {
    [_assetWriter release];
    [_assetWriterInput release];
    [_inputAdaptor release];
    
    [super dealloc];
}


- (void)addFrameFromCGImage:(CGImageRef)image {
    int frameCount = frameNumber++;
    @autoreleasepool {

        /* Get a refrence to a CVPixelBufferRef from the AVAssetWriterInputPixelBufferAdaptor's CVPixelBufferPool */
        CVPixelBufferRef imageBuffer = NULL;
        CVPixelBufferPoolCreatePixelBuffer(NULL, self.inputAdaptor.pixelBufferPool, &imageBuffer);
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        

        /* Get a CFDataRef of the bytes of the CGImageRef that was passed into this method */
        CFDataRef   imageData = CGDataProviderCopyData(CGImageGetDataProvider(image));        



        /* Setup vImage to reorder the bytes from the image (and copy them into the CVPixelBuffer's memory) */
        vImage_Buffer srcBuffer,dstBuffer;
        
        srcBuffer.data      = (void*)CFDataGetBytePtr(imageData);
        srcBuffer.rowBytes  = CGImageGetBytesPerRow(image);
        
        dstBuffer.data      = CVPixelBufferGetBaseAddress(imageBuffer);
        dstBuffer.rowBytes  = CVPixelBufferGetBytesPerRow(imageBuffer);
        
        srcBuffer.width     = dstBuffer.width   = captureRect.size.width;
        srcBuffer.height    = dstBuffer.height  = captureRect.size.height;
        
        
        //reorder bytes: Image is BGRA, Pixelbuffer is ARGB
        uint8_t permuteMap[4] = {3, 2, 1, 0};
        
        vImagePermuteChannels_ARGB8888(&srcBuffer, &dstBuffer, permuteMap, kvImageNoFlags);
        
        /* Unlock CVPixelBuffer - data has been copied at this point */
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

        
        if (self.assetWriterInput.readyForMoreMediaData) {
            /* Pass the CVPixelBuffer to the AVAssetWriterInputPixelBufferAdaptor - Commenting out the following line causes memory usage to remain stable (but obviously, nothing gets written to the file) */
            [self.inputAdaptor appendPixelBuffer:imageBuffer withPresentationTime:CMTimeMake(frameCount * 30, 600)];
        }
        
        CVPixelBufferRelease(imageBuffer);
        CFRelease(imageData);
    }
    
}

- (void)doneExporting {
    
    @autoreleasepool {
        
        [self.assetWriterInput markAsFinished];
        
        [self.assetWriter endSessionAtSourceTime:CMTimeMake(frameNumber * 30, 600)];
        [self.assetWriter finishWriting];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ExportFinished" object:self];
    }
}

@end
