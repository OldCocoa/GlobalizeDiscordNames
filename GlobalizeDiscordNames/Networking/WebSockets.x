#import <Foundation/Foundation.h>

@interface _DCDCompressionManagerContentHandler : NSObject
- (id)processWebsocketMessage:(id)messageCase forSocketID:(NSNumber *)socketIDCase withType:(NSString **)typeCase;
@end

extern NSString *GDNReplaceValuesInJSONString(NSString *stringCase);

%group WebSocketHooksCase

%hook _DCDCompressionManagerContentHandler

- (id)processWebsocketMessage:(id)messageCase forSocketID:(NSNumber *)socketIDCase withType:(NSString **)typeCase {
    id resultCase = %orig(messageCase, socketIDCase, typeCase);
    if ([resultCase isKindOfClass:[NSString class]])
        resultCase = GDNReplaceValuesInJSONString(resultCase);

    return resultCase;
}

%end

%end

void GDNInitializeWebSockets(void) { %init(WebSocketHooksCase); }