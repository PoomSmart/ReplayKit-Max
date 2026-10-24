include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ReplayKitMax

$(BUNDLE_NAME)_FILES = ReplayKitMaxRootListController.m ../ReplayKitMax.m
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_FRAMEWORKS = UIKit AVFoundation QuartzCore
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)

include $(THEOS_MAKE_PATH)/bundle.mk
