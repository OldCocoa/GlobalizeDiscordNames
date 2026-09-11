ARCHS = armv7 arm64

TARGET = iphone:clang:10.3:9.0 # iOS 10.3 SDK, iOS 9.0 build target
INSTALL_TARGET_PROCESSES = Discord

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalizeDiscordNames
GlobalizeDiscordNames_FILES = \
    Tweak.x \
    Networking/API.x \
    Networking/WebSockets.x \
    Replacers/DiscriminatorRandomizer.x \
    Replacers/NameReplacement.x \
    Replacers/ValueReplacement.x
DEBUG.CFLAGS = -DDEBUG -O1
GlobalizeDiscordNames_CFLAGS = -fobjc-arc
GlobalizeDiscordNames_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk