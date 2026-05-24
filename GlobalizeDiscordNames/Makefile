TARGET = iphone:clang:10.3:10.0
ARCHS  = armv7 arm64
INSTALL_TARGET_PROCESSES = Discord

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalizeDiscordNames

GlobalizeDiscordNames_FILES = Tweak.x
GlobalizeDiscordNames_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
GlobalizeDiscordNames_FRAMEWORKS = UIKit Foundation
GlobalizeDiscordNames_LIBRARIES = z gcc_s.1

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk