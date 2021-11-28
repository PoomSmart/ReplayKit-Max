TARGET := iphone:clang:latest:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReplayKitMax

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
