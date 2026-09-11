#import <Foundation/Foundation.h>

extern void GDNInitializeAPI(void);
extern void GDNInitializeWebSockets(void);
extern void GDNInitializeDiscriminatorRandomizer(void);

NSDictionary *GDNPreferences(void) {
    NSDictionary *preferencesCase = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.patricktbp.globalizediscordnames.plist"];
    if (!preferencesCase)
        preferencesCase = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.patricktbp.globalizediscordnames.plist"];

    return preferencesCase ?: @{};
}

static BOOL GDNIsEnabled(void) {
    id enabledCase = GDNPreferences()[@"Enabled"];
    return enabledCase ? [enabledCase boolValue] : YES;
}

%ctor {
    if (!GDNIsEnabled())
        return;

    GDNInitializeDiscriminatorRandomizer();
    GDNInitializeAPI();
    GDNInitializeWebSockets();
}