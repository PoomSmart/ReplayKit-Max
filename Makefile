ROOTLESS ?= 0

ifeq ($(ROOTLESS),1)
	THEOS_LAYOUT_DIR_NAME = layout-rootless
	THEOS_PACKAGE_SCHEME = rootless
endif
TARGET = iphone:clang:latest:14.0
PACKAGE_VERSION = 1.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReplayKitMax

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
