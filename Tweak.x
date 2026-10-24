// Settings live in com.apple.replayd (Settings, or defaults).
// RPEnabled defaults to on when the key is absent.
// RPHighFPSCapture, RPHEVCCapture, and RPHDR10Capture default to off.

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <notify.h>
#import <PSHeader/Misc.h>
#import <VideoToolbox/VideoToolbox.h>

static CFStringRef const kRKPrefsDomain = CFSTR("com.apple.replayd");
static CFStringRef const kRKPrefsNotification = CFSTR("com.ps.replaykitmax.prefs");
static const NSInteger kRKHighCaptureFrameRate = 120;

static BOOL rkTweakEnabled = YES;
static BOOL rkHighFPS = NO;
static BOOL rkHEVC = NO;
static BOOL rkHDR10 = NO;

static BOOL RKPrefBool(CFStringRef key, BOOL fallback) {
    Boolean exists = false;
    Boolean value = CFPreferencesGetAppBooleanValue(key, kRKPrefsDomain, &exists);
    return exists ? value : fallback;
}

static void RKReloadPrefs(void) {
    CFPreferencesAppSynchronize(kRKPrefsDomain);
    rkTweakEnabled = RKPrefBool(CFSTR("RPEnabled"), YES);
    BOOL enabled = rkTweakEnabled;
    rkHighFPS = enabled && RKPrefBool(CFSTR("RPHighFPSCapture"), NO);
    rkHEVC = enabled && RKPrefBool(CFSTR("RPHEVCCapture"), NO);
    rkHDR10 = enabled && RKPrefBool(CFSTR("RPHDR10Capture"), NO);
}

static void RKPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    RKReloadPrefs();
}

static NSString *RKHEVCVideoCodecType(void) {
    if (@available(iOS 11.0, *))
        return AVVideoCodecTypeHEVC;
    return nil;
}

static CMTime RKMinFrameInterval(void) {
    return CMTimeMake(1, (int32_t)kRKHighCaptureFrameRate);
}

// iOS 14+
%hook RPHardwareUtility

// Cap: 1920x1920
+ (CGSize)limitRecordingWindowSizeFromSize:(CGSize)size {
    if (!rkTweakEnabled)
        return %orig;
    return size;
}

%end

// iOS 10 - 13
%hook RPRecordingSession

// Cap (iOS 10): 1600x1600
// Cap (iOS 11 - 13): 1920x1920
- (CGSize)_maximumSizeWithSize:(CGSize)size {
    if (!rkTweakEnabled)
        return %orig;
    return size;
}

%end

// iOS 9
%hook RPRecordingManager

// Cap: 1600x1600
- (CGSize)maximumSizeWithSize:(CGSize)size {
    if (!rkTweakEnabled)
        return %orig;
    return size;
}

%end

@interface RPMovieWriter : NSObject
@property (retain, nonatomic) AVAssetWriter *assetWriter;
@property (retain, nonatomic) AVAssetWriterInput *videoInput;
@end

static BOOL rkCanAddAssetWriterInput = YES;

static void RKPatchMovieWriterVideoInput(RPMovieWriter *writer, BOOL highFPS, BOOL hevc) {
    if (!highFPS && !hevc)
        return;

    NSDictionary *originalOutputSettings = writer.videoInput.outputSettings;
    if (!originalOutputSettings)
        return;

    NSMutableDictionary *outputSettings = [originalOutputSettings mutableCopy];
    NSDictionary *compression = outputSettings[AVVideoCompressionPropertiesKey];
    NSMutableDictionary *compressionSettings = compression ? [compression mutableCopy] : [NSMutableDictionary dictionary];

    if (highFPS) {
        compressionSettings[AVVideoExpectedSourceFrameRateKey] = @(kRKHighCaptureFrameRate);
        compressionSettings[AVVideoMaxKeyFrameIntervalKey] = @(kRKHighCaptureFrameRate);
        [compressionSettings removeObjectForKey:AVVideoAverageBitRateKey];
    }

    if (hevc) {
        if (@available(iOS 11.0, *)) {
            outputSettings[AVVideoCodecKey] = AVVideoCodecTypeHEVC;
            CFStringRef profile = rkHDR10 ? kVTProfileLevel_HEVC_Main10_AutoLevel : kVTProfileLevel_HEVC_Main_AutoLevel;
            compressionSettings[AVVideoProfileLevelKey] = (__bridge NSString *)profile;
        }
    }

    outputSettings[AVVideoCompressionPropertiesKey] = compressionSettings;

    AVAssetWriterInput *previousInput = writer.videoInput;
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    videoInput.expectsMediaDataInRealTime = previousInput.expectsMediaDataInRealTime;
    writer.videoInput = videoInput;

    rkCanAddAssetWriterInput = YES;
    [writer.assetWriter addInput:videoInput];
}

%group WriterPatches

%hook AVAssetWriter

- (void)addInput:(AVAssetWriterInput *)input {
    if (!rkCanAddAssetWriterInput && [input isKindOfClass:[AVAssetWriterInput class]])
        return;
    %orig;
}

%end

%hook RPMovieWriter

- (instancetype)initWithWindowSize:(CGSize)windowSize outputPath:(NSString *)outputPath videoCodecType:(NSString *)videoCodecType assetWriterSetting:(id)assetWriterSetting {
    NSString *hevcCodec = RKHEVCVideoCodecType();
    if (rkHEVC && hevcCodec)
        videoCodecType = hevcCodec;
    return %orig(windowSize, outputPath, videoCodecType, assetWriterSetting);
}

- (instancetype)initWithWindowSize:(CGSize)windowSize outputPath:(NSString *)outputPath videoCodecType:(NSString *)videoCodecType audioCodecType:(NSString *)audioCodecType assetWriterSetting:(id)assetWriterSetting {
    NSString *hevcCodec = RKHEVCVideoCodecType();
    if (rkHEVC && hevcCodec)
        videoCodecType = hevcCodec;
    return %orig(windowSize, outputPath, videoCodecType, audioCodecType, assetWriterSetting);
}

- (void)setVideoCodecType:(NSString *)videoCodecType {
    NSString *hevcCodec = RKHEVCVideoCodecType();
    if (rkHEVC && hevcCodec)
        videoCodecType = hevcCodec;
    %orig(videoCodecType);
}

- (void)setupAssetWriter {
    if (!rkHighFPS && !rkHEVC) {
        %orig;
        return;
    }

    rkCanAddAssetWriterInput = NO;
    %orig;
    RKPatchMovieWriterVideoInput(self, rkHighFPS, rkHEVC);
    rkCanAddAssetWriterInput = YES;
}

- (void)setUpAssetWriterWithHandler:(id)handler {
    if (!rkHighFPS && !rkHEVC) {
        %orig(handler);
        return;
    }

    rkCanAddAssetWriterInput = NO;
    %orig(handler);
    RKPatchMovieWriterVideoInput(self, rkHighFPS, rkHEVC);
    rkCanAddAssetWriterInput = YES;
}

%end

%end

@interface SCCaptureSession : NSObject
@end

%group HEVC

%hook SCCaptureSession

- (void)setupAssetWriterWithExtensionToken:(id)extensionToken outputFileType:(NSString *)outputFileType videoCodecType:(NSString *)videoCodecType mixesAudioWithMicrophone:(BOOL)mixesAudioWithMicrophone {
    NSString *hevcCodec = RKHEVCVideoCodecType();
    if (rkHEVC && hevcCodec)
        videoCodecType = hevcCodec;
    %orig(extensionToken, outputFileType, videoCodecType, mixesAudioWithMicrophone);
}

%end

@interface RPFeatureFlagUtility : NSObject
- (BOOL)replayKitScreenRecordingHEVC;
@end

%hook RPFeatureFlagUtility

- (BOOL)replayKitScreenRecordingHEVC {
    if (rkHEVC)
        return YES;
    return %orig;
}

%end

%hook RPHardwareUtility

+ (CGSize)limitRecordingSizeForH264:(CGSize)size {
    if (rkHEVC)
        return size;
    return %orig(size);
}

%end

%end

%group HighFPS

%hookf(CMTime, CMTimeMake, int32_t value, int32_t timescale) {
    if (rkHighFPS && value == 1 && timescale == 60)
        return %orig(1, (int32_t)kRKHighCaptureFrameRate);
    return %orig(value, timescale);
}

%end

@interface FigScreenCaptureConfiguration : NSObject
- (void)setMinFrameInterval:(const CMTime *)interval;
@end

%hook FigScreenCaptureConfiguration

- (void)setMinFrameInterval:(const CMTime *)interval {
    if (rkHighFPS) {
        CMTime updated = RKMinFrameInterval();
        %orig(&updated);
        return;
    }
    %orig(interval);
}

%end

@interface FigScreenCaptureController : NSObject
+ (instancetype)screenCaptureControllerWithSize:(CGSize)size minIntervalBetweenFrames:(CMTime)interval;
@end

%hook FigScreenCaptureController

+ (instancetype)screenCaptureControllerWithSize:(CGSize)size minIntervalBetweenFrames:(CMTime)interval {
    if (rkHighFPS)
        interval = RKMinFrameInterval();
    return %orig(size, interval);
}

%end

static CFStringRef RKReadableStringSymbol(const char *name) {
    CFStringRef *slot = (CFStringRef *)_PSFindSymbolReadable(NULL, name);
    if (!slot || !*slot)
        return NULL;
    return (CFStringRef)make_sym_readable((void *)*slot);
}

static CFStringRef RKVirtualDisplayVSyncRateKey(void) {
    static CFStringRef key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = RKReadableStringSymbol("_kFigVirtualDisplaySinkOption_VSyncRate");
    });
    return key;
}

static CFStringRef RKVirtualDisplayDeviceInfoKey(void) {
    static CFStringRef key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = RKReadableStringSymbol("_kFigVirtualDisplaySinkProperty_DeviceInfo");
    });
    return key;
}

static CFStringRef RKVirtualDisplayHDRInfoKey(void) {
    static CFStringRef key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = RKReadableStringSymbol("_kFigVirtualDisplaySinkDeviceInfoKey_HDRInfo");
    });
    return key;
}

static CFStringRef RKVirtualDisplayHDRModeKey(void) {
    static CFStringRef key;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        key = RKReadableStringSymbol("_kFigVirtualDisplayModeOption_HDRMode");
    });
    return key;
}

static void RKSetHDR10Mode(CFMutableDictionaryRef options) {
    CFStringRef deviceInfoKey = RKVirtualDisplayDeviceInfoKey();
    CFStringRef hdrInfoKey = RKVirtualDisplayHDRInfoKey();
    CFStringRef hdrModeKey = RKVirtualDisplayHDRModeKey();
    if (!deviceInfoKey || !hdrInfoKey || !hdrModeKey)
        return;

    CFDictionaryRef deviceInfo = CFDictionaryGetValue(options, deviceInfoKey);
    CFMutableDictionaryRef deviceCopy = NULL;
    if (deviceInfo && CFGetTypeID(deviceInfo) == CFDictionaryGetTypeID())
        deviceCopy = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, deviceInfo);
    else
        deviceCopy = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (!deviceCopy)
        return;

    CFMutableDictionaryRef hdrInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (!hdrInfo) {
        CFRelease(deviceCopy);
        return;
    }

    CFDictionarySetValue(hdrInfo, hdrModeKey, CFSTR("HDR10"));
    CFDictionarySetValue(deviceCopy, hdrInfoKey, hdrInfo);
    CFDictionarySetValue(options, deviceInfoKey, deviceCopy);
    CFRelease(hdrInfo);
    CFRelease(deviceCopy);
}

static CFDictionaryRef RKOptionsByApplyingCapturePrefs(CFDictionaryRef options) {
    if ((!rkHighFPS && !rkHDR10) || !options)
        return NULL;
    if (CFGetTypeID(options) != CFDictionaryGetTypeID())
        return NULL;

    CFStringRef vsyncKey = rkHighFPS ? RKVirtualDisplayVSyncRateKey() : NULL;
    if (!vsyncKey && !rkHDR10)
        return NULL;

    CFMutableDictionaryRef copy = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, options);
    if (!copy)
        return NULL;

    if (vsyncKey) {
        int rate = (int)kRKHighCaptureFrameRate;
        CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &rate);
        if (number) {
            CFDictionarySetValue(copy, vsyncKey, number);
            CFRelease(number);
        }
    }

    if (rkHDR10)
        RKSetHDR10Mode(copy);

    return copy;
}

%group VirtualDisplaySession

%hookf(int, FigVirtualDisplaySessionCreateWithConfiguration, void *allocator, CFDictionaryRef options, void **outSession) {
    CFDictionaryRef patched = RKOptionsByApplyingCapturePrefs(options);
    int status = %orig(allocator, patched ? patched : options, outSession);
    if (patched)
        CFRelease(patched);
    return status;
}

%end

%group VirtualDisplayReceiver

%hookf(int, FigVirtualDisplaySessionRemoteFrameReceiverCreate, void *allocator, CFDictionaryRef options, void *callback, void **outSession) {
    CFDictionaryRef patched = RKOptionsByApplyingCapturePrefs(options);
    int status = %orig(allocator, patched ? patched : options, callback, outSession);
    if (patched)
        CFRelease(patched);
    return status;
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, RKPrefsChanged, kRKPrefsNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    RKReloadPrefs();

    %init();
    %init(WriterPatches);
    %init(HEVC);
    %init(HighFPS);

    void *sessionCreate = MSFindSymbol(NULL, "_FigVirtualDisplaySessionCreateWithConfiguration");
    if (sessionCreate)
        %init(VirtualDisplaySession, FigVirtualDisplaySessionCreateWithConfiguration = sessionCreate);

    void *receiverCreate = MSFindSymbol(NULL, "_FigVirtualDisplaySessionRemoteFrameReceiverCreate");
    if (receiverCreate)
        %init(VirtualDisplayReceiver, FigVirtualDisplaySessionRemoteFrameReceiverCreate = receiverCreate);
}
