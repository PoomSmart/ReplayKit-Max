#import "ReplayKitMax.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

BOOL RKDisplaySupports120FPS(void) {
    UIScreen *screen = [UIScreen mainScreen];
    if ([screen respondsToSelector:@selector(maximumFramesPerSecond)] && screen.maximumFramesPerSecond >= 120)
        return YES;

    CADisplay *display = [CADisplay mainDisplay];
    if (![display respondsToSelector:@selector(availableModes)])
        return NO;
    for (CADisplayMode *mode in [display availableModes]) {
        if (![mode respondsToSelector:@selector(refreshRate)])
            continue;
        if ([mode refreshRate] >= 119.0)
            return YES;
    }
    return NO;
}

BOOL RKDisplaySupportsHDR10(void) {
    CADisplay *display = [CADisplay mainDisplay];
    if (![display respondsToSelector:@selector(supportedHDRModes)])
        return NO;
    for (id mode in [display supportedHDRModes]) {
        if ([mode isKindOfClass:[NSString class]] && [mode isEqualToString:@"HDR10"])
            return YES;
    }
    return NO;
}

BOOL RKDeviceSupportsHEVC(void) {
    if (@available(iOS 11.0, *))
        return [[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPresetHEVCHighestQuality];
    return NO;
}
