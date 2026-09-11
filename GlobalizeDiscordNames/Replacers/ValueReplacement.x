#import <Foundation/Foundation.h>

extern BOOL GDNReplaceNameInDictionary(NSMutableDictionary *dictionaryCase);
extern BOOL GDNReplaceDiscriminatorInDictionary(NSMutableDictionary *dictionaryCase);

static BOOL GDNReplaceValuesInObjectCase(id objectCase) {
    BOOL changedCase = NO;

    if ([objectCase isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dictionaryCase = (NSMutableDictionary *)objectCase;

        if (GDNReplaceNameInDictionary(dictionaryCase))
            changedCase = YES;
        if (GDNReplaceDiscriminatorInDictionary(dictionaryCase))
            changedCase = YES;

        for (id valueCase in [dictionaryCase allValues]) {
            if (GDNReplaceValuesInObjectCase(valueCase))
                changedCase = YES;
        }
    } else if ([objectCase isKindOfClass:[NSMutableArray class]]) {
        for (id valueCase in (NSMutableArray *)objectCase) {
            if (GDNReplaceValuesInObjectCase(valueCase))
                changedCase = YES;
        }
    }

    return changedCase;
}

NSData *GDNReplaceValuesInJSONData(NSData *dataCase) {
    if (!dataCase.length)
        return dataCase;

    NSError *errorCase = nil;
    id jsonCase = [NSJSONSerialization JSONObjectWithData:dataCase options:NSJSONReadingMutableContainers error:&errorCase];

    if (!jsonCase || errorCase || !GDNReplaceValuesInObjectCase(jsonCase))
        return dataCase;

    NSData *modifiedDataCase = [NSJSONSerialization dataWithJSONObject:jsonCase options:0 error:&errorCase];
    return modifiedDataCase && !errorCase ? modifiedDataCase : dataCase;
}

NSString *GDNReplaceValuesInJSONString(NSString *stringCase) {
    if (!stringCase.length)
        return stringCase;

    NSData *dataCase = [stringCase dataUsingEncoding:NSUTF8StringEncoding];
    if (!dataCase)
        return stringCase;

    NSData *modifiedDataCase = GDNReplaceValuesInJSONData(dataCase);
    if (modifiedDataCase == dataCase)
        return stringCase;

    NSString *modifiedStringCase = [[NSString alloc] initWithData:modifiedDataCase encoding:NSUTF8StringEncoding];
    return modifiedStringCase ?: stringCase;
}