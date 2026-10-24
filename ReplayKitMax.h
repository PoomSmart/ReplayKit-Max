#import <Foundation/Foundation.h>

@interface CADisplayMode : NSObject
- (double)refreshRate;
@end

@interface CADisplay : NSObject
+ (CADisplay *)mainDisplay;
- (NSArray *)availableModes;
- (NSArray *)supportedHDRModes;
@end

BOOL RKDisplaySupports120FPS(void);
BOOL RKDisplaySupportsHDR10(void);
BOOL RKDeviceSupportsHEVC(void);
