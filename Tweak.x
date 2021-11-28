#import <AVFoundation/AVFoundation.h>

// Future plan: Make it records in 120 FPS for devices that support it

// BOOL canAddInput = YES;

// @interface RPMovieWriter : NSObject
// @property (retain, nonatomic) AVAssetWriter *assetWriter;
// @property (retain, nonatomic) AVAssetWriterInput *videoInput;
// @end

// %hook AVAssetWriter

// - (void)addInput:(id)input {
//     if (!canAddInput && [input isKindOfClass:[AVAssetWriterInput class]]) return;
//     %orig;
// }

// %end

// %hook RPMovieWriter

// - (void)setUpAssetWriterWithHandler:(id)handler {
//     canAddInput = NO;
//     %orig;
//     NSDictionary *originalOutputSettings = self.videoInput.outputSettings;
//     if (originalOutputSettings) {
//         NSMutableDictionary *outputSettings = originalOutputSettings.mutableCopy;
//         NSMutableDictionary *compressionSettings = outputSettings[AVVideoCompressionPropertiesKey];
//         [compressionSettings removeObjectForKey:AVVideoAverageBitRateKey];
//         compressionSettings[AVVideoExpectedSourceFrameRateKey] = @(120);
//         compressionSettings[AVVideoMaxKeyFrameIntervalKey] = @(120);
//         self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
//         canAddInput = YES;
//         [self.assetWriter addInput:self.videoInput];
//     } else
//         canAddInput = YES;
// }

// %end

%hook RPHardwareUtility

+ (CGSize)limitRecordingWindowSizeFromSize:(CGSize)size {
    return size;
}

%end