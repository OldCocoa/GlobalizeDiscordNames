include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GlobalizeDiscordNamesPrefs
GlobalizeDiscordNamesPrefs_FILES = GDNRootListController.m
GlobalizeDiscordNamesPrefs_CFLAGS = -fobjc-arc
GlobalizeDiscordNamesPrefs_FRAMEWORKS = UIKit
GlobalizeDiscordNamesPrefs_PRIVATE_FRAMEWORKS = Preferences
GlobalizeDiscordNamesPrefs_RESOURCE_DIRS = Resources
GlobalizeDiscordNamesPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GlobalizeDiscordNames.plist"$(ECHO_END)