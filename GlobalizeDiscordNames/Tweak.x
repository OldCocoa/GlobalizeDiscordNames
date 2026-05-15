#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <zlib.h>
#import <notify.h>

static NSString * const kGDNPrefsDomain = @"com.patricktbp.globalizediscordnames";
static NSString * const kGDNPrefsChangedNotification = @"com.patricktbp.globalizediscordnames/PrefsChanged";
static NSString * const kGDNHandledKey = @"GDNHandled";

static BOOL gGDN_enabled = YES;
static BOOL gGDN_useGlobalName = YES;
static BOOL gGDN_overrideDiscriminator = YES;
static NSString *gGDN_customDiscriminator = @"0001";
static BOOL gGDN_showLaunchAlert = YES;
static BOOL gGDN_alertShown = NO;


static BOOL gdn_prefBool(NSString *key, BOOL fallback) {
	CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
	                                                (__bridge CFStringRef)kGDNPrefsDomain);
	if (!v) return fallback;
	id obj = (__bridge_transfer id)v;
	if ([obj isKindOfClass:[NSNumber class]]) return [obj boolValue];
	return fallback;
}

static NSString *gdn_prefString(NSString *key, NSString *fallback) {
	CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
	                                                (__bridge CFStringRef)kGDNPrefsDomain);
	if (!v) return fallback;
	id obj = (__bridge_transfer id)v;
	if ([obj isKindOfClass:[NSString class]] && [(NSString *)obj length] > 0) return obj;
	return fallback;
}

static void gdn_loadPrefs(void) {
	gGDN_enabled = gdn_prefBool(@"Enabled", YES);
	gGDN_useGlobalName = gdn_prefBool(@"UseGlobalName", YES);
	gGDN_overrideDiscriminator = gdn_prefBool(@"OverrideDiscriminator", YES);
	gGDN_customDiscriminator = gdn_prefString(@"CustomDiscriminator", @"0001");
	gGDN_showLaunchAlert = gdn_prefBool(@"ShowLaunchAlert", YES);
}

static void gdn_prefsChanged(CFNotificationCenterRef center, void *observer,
                             CFStringRef name, const void *object,
                             CFDictionaryRef userInfo) {
	gdn_loadPrefs();
}


static void gdn_patchUserObjects(id obj) {
	if ([obj isKindOfClass:[NSDictionary class]]) {
		BOOL isMutable = [obj isKindOfClass:[NSMutableDictionary class]];
		NSMutableDictionary *dict = (NSMutableDictionary *)obj;

		if (isMutable) {
			id username = dict[@"username"];
			id discriminator = dict[@"discriminator"];

			if ([username isKindOfClass:[NSString class]] && discriminator != nil) {
				if (gGDN_useGlobalName) {
					id globalName = dict[@"global_name"];
					if ([globalName isKindOfClass:[NSString class]] &&
					    [(NSString *)globalName length] > 0) {
						dict[@"username"] = globalName;
					}
				}
				if (gGDN_overrideDiscriminator) {
					dict[@"discriminator"] = gGDN_customDiscriminator ?: @"0001";
				}
			}
		}

		for (id key in [dict allKeys]) {
			id val = dict[key];
			if ([val isKindOfClass:[NSDictionary class]] ||
			    [val isKindOfClass:[NSArray class]]) {
				gdn_patchUserObjects(val);
			}
		}

	} else if ([obj isKindOfClass:[NSArray class]]) {
		for (id item in (NSArray *)obj) {
			if ([item isKindOfClass:[NSDictionary class]] ||
			    [item isKindOfClass:[NSArray class]]) {
				gdn_patchUserObjects(item);
			}
		}
	}
}

static NSString *gdn_patchJSONString(NSString *jsonString) {
	NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	if (!data) return nil;

	NSError *err = nil;
	id obj = [NSJSONSerialization JSONObjectWithData:data
	                                         options:NSJSONReadingMutableContainers
	                                           error:&err];
	if (!obj || err) return nil;

	gdn_patchUserObjects(obj);

	NSData *outData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&err];
	if (!outData) return nil;

	return [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
}


@interface GDNZlibContext : NSObject {
@public
	z_stream _stream;
	NSMutableData *_accumulated;
	BOOL _ready;
}
@end

@implementation GDNZlibContext

- (instancetype)init {
	if ((self = [super init])) {
		memset(&_stream, 0, sizeof(_stream));
		if (inflateInit(&_stream) != Z_OK) {
			return nil;
		}
		_accumulated = [NSMutableData data];
		_ready = YES;
	}
	return self;
}

- (void)dealloc {
	if (_ready) inflateEnd(&_stream);
}

@end


static const char kGDNZlibKey = 0;

static GDNZlibContext *gdn_zlibFor(id socket) {
	GDNZlibContext *ctx = objc_getAssociatedObject(socket, &kGDNZlibKey);
	if (!ctx) {
		ctx = [[GDNZlibContext alloc] init];
		if (ctx) {
			objc_setAssociatedObject(socket, &kGDNZlibKey, ctx,
			                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}
	return ctx;
}

static NSString *gdn_inflateBinaryFrame(id socket, NSData *frame) {
	GDNZlibContext *ctx = gdn_zlibFor(socket);
	if (!ctx || !ctx->_ready) return nil;

	NSUInteger len = frame.length;
	if (len == 0) return nil;

	const uint8_t *bytes = (const uint8_t *)frame.bytes;
	BOOL endsWithFlush = (len >= 4 &&
	                     bytes[len - 4] == 0x00 && bytes[len - 3] == 0x00 &&
	                     bytes[len - 2] == 0xFF && bytes[len - 1] == 0xFF);

	ctx->_stream.next_in = (Bytef *)bytes;
	ctx->_stream.avail_in = (uInt)len;

	uint8_t out[16384];

	while (1) {
		ctx->_stream.next_out = out;
		ctx->_stream.avail_out = sizeof(out);

		int rc = inflate(&ctx->_stream, Z_SYNC_FLUSH);

		if (rc != Z_OK && rc != Z_BUF_ERROR && rc != Z_STREAM_END) {
			inflateEnd(&ctx->_stream);
			memset(&ctx->_stream, 0, sizeof(ctx->_stream));
			inflateInit(&ctx->_stream);
			[ctx->_accumulated setLength:0];
			return nil;
		}

		NSUInteger produced = sizeof(out) - ctx->_stream.avail_out;
		if (produced > 0) {
			[ctx->_accumulated appendBytes:out length:produced];
		}

		if (ctx->_stream.avail_in == 0 && ctx->_stream.avail_out != 0) break;
		if (rc == Z_STREAM_END) break;
	}

	if (!endsWithFlush) return nil;

	NSData *complete = [ctx->_accumulated copy];
	[ctx->_accumulated setLength:0];

	return [[NSString alloc] initWithData:complete encoding:NSUTF8StringEncoding];
}


%hook RCTWebSocketModule

- (void)webSocket:(id)webSocket didReceiveMessage:(id)message {
	if (!gGDN_enabled) { %orig; return; }

	@try {
		if ([message isKindOfClass:[NSString class]]) {
			NSString *patched = gdn_patchJSONString((NSString *)message);
			if (patched) {
				%orig(webSocket, patched);
				return;
			}

		} else if ([message isKindOfClass:[NSData class]]) {
			NSString *inflated = gdn_inflateBinaryFrame(webSocket, (NSData *)message);
			if (inflated) {
				NSString *patched = gdn_patchJSONString(inflated) ?: inflated;
				%orig(webSocket, patched);
				return;
			}
			return;
		}
	} @catch (NSException *e) {
	}

	%orig;
}

%end


static BOOL gdn_isDiscordAPIURL(NSURL *url) {
	NSString *host = url.host.lowercaseString;
	if (!host) return NO;

	if ([host hasPrefix:@"cdn."] || [host hasPrefix:@"media."] ||
	    [host hasPrefix:@"images."]) return NO;

	return [host isEqualToString:@"discord.com"] ||
	       [host isEqualToString:@"discordapp.com"] ||
	       [host hasSuffix:@".discord.com"] ||
	       [host hasSuffix:@".discordapp.com"];
}


@interface GDNURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *buffer;
@end

@implementation GDNURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	if ([NSURLProtocol propertyForKey:kGDNHandledKey inRequest:request]) return NO;
	if (!gGDN_enabled) return NO;
	return gdn_isDiscordAPIURL(request.URL);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

- (void)startLoading {
	NSMutableURLRequest *mreq = [self.request mutableCopy];
	[NSURLProtocol setProperty:@YES forKey:kGDNHandledKey inRequest:mreq];

	self.buffer = [NSMutableData data];

	NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
	self.session = [NSURLSession sessionWithConfiguration:cfg
	                                             delegate:self
	                                        delegateQueue:nil];
	self.dataTask = [self.session dataTaskWithRequest:mreq];
	[self.dataTask resume];
}

- (void)stopLoading {
	[self.dataTask cancel];
	[self.session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
	[self.client URLProtocol:self
	      didReceiveResponse:response
	      cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
	[self.buffer appendData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
	if (error) {
		[self.client URLProtocol:self didFailWithError:error];
		return;
	}

	NSData *out = self.buffer;

	@try {
		if (out.length > 0) {
			NSString *str = [[NSString alloc] initWithData:out encoding:NSUTF8StringEncoding];
			if (str) {
				NSString *patched = gdn_patchJSONString(str);
				if (patched) {
					out = [patched dataUsingEncoding:NSUTF8StringEncoding] ?: out;
				}
			}
		}
	} @catch (NSException *e) {
	}

	[self.client URLProtocol:self didLoadData:out];
	[self.client URLProtocolDidFinishLoading:self];
}

@end


%hook NSURLSessionConfiguration

+ (instancetype)defaultSessionConfiguration {
	NSURLSessionConfiguration *cfg = %orig;
	NSMutableArray *protos = [NSMutableArray arrayWithArray:cfg.protocolClasses ?: @[]];
	if (![protos containsObject:[GDNURLProtocol class]]) {
		[protos insertObject:[GDNURLProtocol class] atIndex:0];
		cfg.protocolClasses = protos;
	}
	return cfg;
}

+ (instancetype)ephemeralSessionConfiguration {
	NSURLSessionConfiguration *cfg = %orig;
	NSMutableArray *protos = [NSMutableArray arrayWithArray:cfg.protocolClasses ?: @[]];
	if (![protos containsObject:[GDNURLProtocol class]]) {
		[protos insertObject:[GDNURLProtocol class] atIndex:0];
		cfg.protocolClasses = protos;
	}
	return cfg;
}

%end


static UIWindow *gdn_findKeyWindow(void) {
	UIApplication *app = [UIApplication sharedApplication];

	UIWindow *kw = app.keyWindow;
	if (kw && !kw.isHidden && kw.alpha > 0.01f) return kw;

	UIWindow *best = nil;
	CGFloat maxLevel = -CGFLOAT_MAX;

	for (UIWindow *w in app.windows) {
		if (w.isHidden || w.alpha <= 0.01f) continue;
		if (w.windowLevel >= maxLevel) {
			maxLevel = w.windowLevel;
			best = w;
		}
	}

	return best;
}

static void gdn_presentLaunchAlert(void) {
	if (gGDN_alertShown) return;
	gGDN_alertShown = YES;
	if (!gGDN_showLaunchAlert) return;

	dispatch_async(dispatch_get_main_queue(), ^{
		UIWindow *window = gdn_findKeyWindow();
		UIViewController *root = window.rootViewController;

		while (root.presentedViewController) root = root.presentedViewController;

		if (!root) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
			               dispatch_get_main_queue(), ^{
				gGDN_alertShown = NO;
				gdn_presentLaunchAlert();
			});
			return;
		}

		UIAlertController *ac = [UIAlertController
			alertControllerWithTitle:@"GlobalizeDiscordNames"
			                 message:@"Discord has been patched!"
			          preferredStyle:UIAlertControllerStyleAlert];

		[ac addAction:[UIAlertAction actionWithTitle:@"OK"
		                                       style:UIAlertActionStyleDefault
		                                     handler:nil]];

		[root presentViewController:ac animated:YES completion:nil];
	});
}


%ctor {
	@autoreleasepool {
		gdn_loadPrefs();

		[NSURLProtocol registerClass:[GDNURLProtocol class]];

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		                                NULL,
		                                &gdn_prefsChanged,
		                                (__bridge CFStringRef)kGDNPrefsChangedNotification,
		                                NULL,
		                                CFNotificationSuspensionBehaviorDeliverImmediately);

		[[NSNotificationCenter defaultCenter]
			addObserverForName:UIApplicationDidBecomeActiveNotification
			            object:nil
			             queue:[NSOperationQueue mainQueue]
			        usingBlock:^(NSNotification *note) {
				gdn_presentLaunchAlert();
			}];
	}
}