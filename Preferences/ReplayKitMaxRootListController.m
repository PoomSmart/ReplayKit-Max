#import "ReplayKitMaxRootListController.h"
#import "ReplayKitMax.h"
#import <Preferences/PSSpecifier.h>
#import <notify.h>

@implementation ReplayKitMaxRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableSet *hidden = [NSMutableSet set];
        if (!RKDisplaySupports120FPS()) {
            [hidden addObject:@"highFPSGroup"];
            [hidden addObject:@"highFPS"];
        }
        if (!RKDeviceSupportsHEVC()) {
            [hidden addObject:@"hevcGroup"];
            [hidden addObject:@"hevc"];
        }
        if (!RKDisplaySupportsHDR10()) {
            [hidden addObject:@"hdrGroup"];
            [hidden addObject:@"hdr"];
        }

        NSMutableArray *visible = [NSMutableArray array];
        for (PSSpecifier *specifier in [self loadSpecifiersFromPlistName:@"Root" target:self]) {
            NSString *identifier = specifier.properties[@"id"];
            if (identifier && [hidden containsObject:identifier])
                continue;
            if ([identifier isEqualToString:@"hevcGroup"] && ![hidden containsObject:@"hdr"]) {
                [specifier setProperty:@"Saves the recording as HEVC instead of H.264, which keeps the file smaller. Leave this on with HDR10 so the extra color can be stored." forKey:PSFooterTextGroupKey];
            }
            [visible addObject:specifier];
        }
        _specifiers = visible;
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    CFPreferencesAppSynchronize(CFSTR("com.apple.replayd"));
    notify_post("com.ps.replaykitmax.prefs");
}

@end
