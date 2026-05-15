#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <notify.h>

@interface GDNRootListController : PSListController
@end

@implementation GDNRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSString *key = [specifier propertyForKey:@"key"];
	NSString *domain = [specifier propertyForKey:@"defaults"];
	if (!key || !domain) return;

	CFPreferencesSetAppValue((__bridge CFStringRef)key,
	                         (__bridge CFPropertyListRef)value,
	                         (__bridge CFStringRef)domain);
	CFPreferencesAppSynchronize((__bridge CFStringRef)domain);
	notify_post("com.patricktbp.globalizediscordnames/PrefsChanged");
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSString *key = [specifier propertyForKey:@"key"];
	NSString *domain = [specifier propertyForKey:@"defaults"];
	id fallback = [specifier propertyForKey:@"default"];
	if (!key || !domain) return fallback;

	CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)domain);
	if (!v) return fallback;

	return (__bridge_transfer id)v;
}

@end