#import <Foundation/Foundation.h>

BOOL GDNReplaceNameInDictionary(NSMutableDictionary *dictionaryCase) {
    id usernameCase = dictionaryCase[@"username"];
    id globalNameCase = dictionaryCase[@"global_name"];

    if (!usernameCase || ![globalNameCase isKindOfClass:[NSString class]] || [usernameCase isEqual:globalNameCase])
        return NO;

    dictionaryCase[@"username"] = globalNameCase;
    return YES;
}