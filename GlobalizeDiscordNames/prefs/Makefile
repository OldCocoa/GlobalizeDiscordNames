ARCHS  = armv7 arm64
TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GDNPrefs

GDNPrefs_FILES = GDNRootListController.x
GDNPrefs_INSTALL_PATH = /Library/PreferenceBundles
GDNPrefs_FRAMEWORKS = UIKit
GDNPrefs_PRIVATE_FRAMEWORKS = Preferences
GDNPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GDNPrefs.plist$(ECHO_END)