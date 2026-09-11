#import <Foundation/Foundation.h>

extern NSDictionary *GDNPreferences(void);

static NSInteger discriminatorModeCase = 0;
static NSString *fixedDiscriminatorCase = nil;

static NSString *GDNUserIDStringCase(id userIDCase) {
    if ([userIDCase isKindOfClass:[NSString class]])
        return userIDCase;
    if ([userIDCase isKindOfClass:[NSNumber class]])
        return [userIDCase stringValue];

    return nil;
}

static NSString *GDNNormalizedDiscriminatorCase(NSString *discriminatorCase) {
    if (![discriminatorCase isKindOfClass:[NSString class]] || !discriminatorCase.length || discriminatorCase.length > 4)
        return nil;

    NSCharacterSet *nonNumberCase = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([discriminatorCase rangeOfCharacterFromSet:nonNumberCase].location != NSNotFound)
        return nil;

    return [NSString stringWithFormat:@"%04u", (unsigned int)[discriminatorCase intValue]];
}

// The randomizer uses the user ID off of a profile and uses it as the seed of the randomizer, providing a constant discriminator, but still random across profiles.
static NSString *GDNRandomizedDiscriminatorCase(NSString *userIDCase) {
    unsigned long long userIDValueCase = [userIDCase longLongValue];
    uint32_t seedCase = (uint32_t)(userIDValueCase ^ (userIDValueCase >> 32));
    seedCase = seedCase * 1664525u + 1013904223u;

    return [NSString stringWithFormat:@"%04u", (seedCase % 9999u) + 1u];
}

BOOL GDNReplaceDiscriminatorInDictionary(NSMutableDictionary *dictionaryCase) {
    if (discriminatorModeCase == 0)
        return NO;

    NSString *userIDCase = GDNUserIDStringCase(dictionaryCase[@"id"]);
    id usernameCase = dictionaryCase[@"username"];
    id globalNameCase = dictionaryCase[@"global_name"];

    if (!userIDCase.length || (![usernameCase isKindOfClass:[NSString class]] && ![globalNameCase isKindOfClass:[NSString class]]))
        return NO;

    NSString *replacementCase = nil;

    if (discriminatorModeCase == 1)
        replacementCase = GDNRandomizedDiscriminatorCase(userIDCase);
    else if (discriminatorModeCase == 2)
        replacementCase = fixedDiscriminatorCase;

    id discriminatorCase = dictionaryCase[@"discriminator"];
    if (!replacementCase || [discriminatorCase isEqual:replacementCase])
        return NO;

    dictionaryCase[@"discriminator"] = replacementCase;
    return YES;
}

void GDNInitializeDiscriminatorRandomizer(void) {
    NSDictionary *preferencesCase = GDNPreferences();
    
    discriminatorModeCase = [preferencesCase[@"DiscriminatorMode"] integerValue];
    fixedDiscriminatorCase = GDNNormalizedDiscriminatorCase(preferencesCase[@"FixedDiscriminatorValue"]);
}