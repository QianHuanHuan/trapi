TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := PocketOverlayPoC
PocketOverlayPoC_FILES := Tweak.xm
PocketOverlayPoC_CFLAGS := -fobjc-arc
PocketOverlayPoC_FRAMEWORKS := UIKit
PocketOverlayPoC_PLIST := PocketOverlayPoC.plist

include $(THEOS_MAKE_PATH)/tweak.mk
