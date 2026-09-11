#import <Foundation/Foundation.h>

typedef void (^responseSenderBlockCase)(NSArray *responseCase);

@class RCTNetworkTask;

@interface RCTNetworking : NSObject
- (void)sendRequest:(NSURLRequest *)requestCase responseType:(NSString *)responseTypeCase incrementalUpdates:(BOOL)incrementalUpdatesCase responseSender:(responseSenderBlockCase)responseSenderCase;
- (void)sendData:(NSData *)dataCase responseType:(NSString *)responseTypeCase response:(NSURLResponse *)responseCase forTask:(RCTNetworkTask *)taskCase;
@end

extern NSData *GDNReplaceValuesInJSONData(NSData *dataCase);

static BOOL GDNIsDiscordAPIRequest(NSURLRequest *requestCase) {
    NSString *hostCase = requestCase.URL.host;
    NSString *pathCase = requestCase.URL.path;

    if (!hostCase.length || !pathCase.length)
        return NO;

    // The default base URL for the Discord API is https://discord.com/api, but we should take into account all Discord URLs.
    BOOL discordHostCase = [hostCase isEqualToString:@"discord.com"] ||
                           [hostCase hasSuffix:@".discord.com"] ||
                           [hostCase isEqualToString:@"discordapp.com"] ||
                           [hostCase hasSuffix:@".discordapp.com"];

    return discordHostCase && [pathCase hasPrefix:@"/api/"];
}

%group APIHooksCase

%hook RCTNetworking

- (void)sendRequest:(NSURLRequest *)requestCase responseType:(NSString *)responseTypeCase incrementalUpdates:(BOOL)incrementalUpdatesCase responseSender:(responseSenderBlockCase)responseSenderCase {
    if (incrementalUpdatesCase && [responseTypeCase isEqualToString:@"text"] && GDNIsDiscordAPIRequest(requestCase))
        incrementalUpdatesCase = NO;

    %orig(requestCase, responseTypeCase, incrementalUpdatesCase, responseSenderCase);
}

- (void)sendData:(NSData *)dataCase responseType:(NSString *)responseTypeCase response:(NSURLResponse *)responseCase forTask:(RCTNetworkTask *)taskCase {
    if ([responseTypeCase isEqualToString:@"text"])
        dataCase = GDNReplaceValuesInJSONData(dataCase);

    %orig(dataCase, responseTypeCase, responseCase, taskCase);
}

%end

%end

void GDNInitializeAPI(void) { %init(APIHooksCase); }