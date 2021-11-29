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

// - (void)setUpAssetWriter {
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

// iOS 14+
%hook RPHardwareUtility

// Cap: 1920x1920
+ (CGSize)limitRecordingWindowSizeFromSize:(CGSize)size {
    return size;
}

%end

// iOS 10 - 13
%hook RPRecordingSession

// Cap (iOS 10): 1600x1600
// Cap (iOS 11 - 13): 1920x1920
- (CGSize)_maximumSizeWithSize:(CGSize)size {
    return size;
}

%end

// iOS 9
%hook RPRecordingManager

// Cap: 1600x1600
- (CGSize)maximumSizeWithSize:(CGSize)size {
    return size;
}

%end
