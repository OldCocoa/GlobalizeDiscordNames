#import "GDNRootListController.h"
#import <Preferences/PSSpecifier.h>

static CFStringRef const gdnPreferencesDomainCase = CFSTR("com.patricktbp.globalizediscordnames");

@implementation GDNRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];

        fixedDiscriminatorSpecifierCase = [self specifierForID:@"FixedDiscriminatorValue"];
        fixedDiscriminatorVisibleCase = YES;

        PSSpecifier *discriminatorModeSpecifierCase = [self specifierForID:@"DiscriminatorMode"];
        if ([[self readPreferenceValueCase:discriminatorModeSpecifierCase] integerValue] != 2) {
            [self removeSpecifier:fixedDiscriminatorSpecifierCase animated:NO];
            fixedDiscriminatorVisibleCase = NO;
        }
    }

    return _specifiers;
}

- (id)readPreferenceValueCase:(PSSpecifier *)specifierCase {
    NSString *keyCase = [specifierCase propertyForKey:@"key"];
    if (!keyCase)
        return [specifierCase propertyForKey:@"default"];

    CFPreferencesAppSynchronize(gdnPreferencesDomainCase);

    CFPropertyListRef valueCase = CFPreferencesCopyAppValue((__bridge CFStringRef)keyCase, gdnPreferencesDomainCase);
    return valueCase ? CFBridgingRelease(valueCase) : [specifierCase propertyForKey:@"default"];
}

- (void)setPreferenceValueCase:(id)valueCase specifier:(PSSpecifier *)specifierCase {
    NSString *keyCase = [specifierCase propertyForKey:@"key"];
    if (!keyCase)
        return;

    if ([keyCase isEqualToString:@"FixedDiscriminatorValue"] && [valueCase isKindOfClass:[NSString class]]) {
        NSString *stringCase = (NSString *)valueCase;
        NSCharacterSet *nonNumberCase = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        
        stringCase = [[stringCase componentsSeparatedByCharactersInSet:nonNumberCase] componentsJoinedByString:@""];

        if (stringCase.length > 4)
            stringCase = [stringCase substringToIndex:4];

        valueCase = stringCase;
    }

    CFPreferencesSetAppValue((__bridge CFStringRef)keyCase, (__bridge CFPropertyListRef)valueCase, gdnPreferencesDomainCase);
    CFPreferencesAppSynchronize(gdnPreferencesDomainCase);

    if ([keyCase isEqualToString:@"DiscriminatorMode"]) {
        if ([valueCase integerValue] == 2 && !fixedDiscriminatorVisibleCase) {
            [self insertSpecifier:fixedDiscriminatorSpecifierCase afterSpecifier:specifierCase animated:YES];
            fixedDiscriminatorVisibleCase = YES;
        } else if ([valueCase integerValue] != 2 && fixedDiscriminatorVisibleCase) {
            [self removeSpecifier:fixedDiscriminatorSpecifierCase animated:YES];
            fixedDiscriminatorVisibleCase = NO;
        }
    }
}

@end