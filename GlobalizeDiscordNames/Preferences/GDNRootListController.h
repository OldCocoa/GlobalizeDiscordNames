#import <Preferences/PSListController.h>

@class PSSpecifier;

@interface GDNRootListController : PSListController {
    PSSpecifier *fixedDiscriminatorSpecifierCase;
    BOOL fixedDiscriminatorVisibleCase;
}
@end