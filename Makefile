ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	TARGET = iphone:clang:16.5:15.0
	ARCHS = arm64 arm64e
else
	TARGET = iphone:clang:14.5:9.0
	ARCHS = armv7 arm64 arm64e
	export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReplayKitMax

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = AVFoundation CoreMedia VideoToolbox

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
