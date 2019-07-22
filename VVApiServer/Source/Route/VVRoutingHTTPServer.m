#import "VVRoutingHTTPServer.h"

#import "VVRoutingConnection.h"
#import "VVRoute.h"

@implementation VVRoutingHTTPServer {
    NSMutableDictionary *routes;
    NSMutableDictionary *defaultHeaders;
    NSMutableDictionary *mimeTypes;
    dispatch_queue_t routeQueue;
}

@synthesize defaultHeaders;

- (id)init {
    if (self = [super init]) {
        connectionClass = [VVRoutingConnection class];
        routes = [[NSMutableDictionary alloc] init];
        defaultHeaders = [[NSMutableDictionary alloc] init];
        [self setupMIMETypes];
    }
    return self;
}

- (void)setDefaultHeaders:(NSDictionary *)headers {
    if (headers) {
        defaultHeaders = [headers mutableCopy];
    } else {
        defaultHeaders = [[NSMutableDictionary alloc] init];
    }
}

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value {
    defaultHeaders[field] = value;
}

- (dispatch_queue_t)routeQueue {
    return routeQueue;
}

- (void)setRouteQueue:(dispatch_queue_t)queue {
    routeQueue = queue;
}

- (NSDictionary *)mimeTypes {
    return mimeTypes;
}

- (void)setMIMETypes:(NSDictionary *)types {
    NSMutableDictionary *newTypes;
    if (types) {
        newTypes = [types mutableCopy];
    } else {
        newTypes = [[NSMutableDictionary alloc] init];
    }

    mimeTypes = newTypes;
}

- (void)setMIMEType:(NSString *)theType forExtension:(NSString *)ext {
    mimeTypes[ext] = theType;
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if (!ext || [ext length] < 1)
        return nil;

    return mimeTypes[ext];
}

- (void)get:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"GET" withPath:path withHandler:handler];
}

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"POST" withPath:path withHandler:handler];
}

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"PUT" withPath:path withHandler:handler];
}

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"DELETE" withPath:path withHandler:handler];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path withHandler:(VVRequestHandler)handler {
    VVRoute *route = [self routeWithPath:path];
    route.handler = handler;

    [self addRoute:route forMethod:method];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target selector:(SEL)selector {
    VVRoute *route = [self routeWithPath:path];
    route.target = target;
    route.selector = selector;

    [self addRoute:route forMethod:method];
}

- (void)addRoute:(VVRoute *)route forMethod:(NSString *)method {
    method = [method uppercaseString];
    NSMutableArray *methodRoutes = routes[method];
    if (methodRoutes == nil) {
        methodRoutes = [NSMutableArray array];
        routes[method] = methodRoutes;
    }

    [methodRoutes addObject:route];

    // Define a HEAD route for all GET routes
    if ([method isEqualToString:@"GET"]) {
        [self addRoute:route forMethod:@"HEAD"];
    }
}

- (VVRoute *)routeWithPath:(NSString *)path {
    VVRoute *route = [[VVRoute alloc] init];
    NSMutableArray *keys = [NSMutableArray array];

    if ([path length] > 2 && [path characterAtIndex:0] == '{') {
        // This is a custom regular expression, just remove the {}
        path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
    } else {
        NSRegularExpression *regex = nil;

        // Escape regex characters
        regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
        path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];

        // Parse any :parameters and * in the path
        regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)"
                                                          options:0
                                                            error:nil];
        NSMutableString *regexPath = [NSMutableString stringWithString:path];
        __block NSInteger diff = 0;
        [regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
                                 NSString *replacementString;

                                 NSString *capturedString = [path substringWithRange:result.range];
                                 if ([capturedString isEqualToString:@"*"]) {
                                     [keys addObject:@"wildcards"];
                                     replacementString = @"(.*?)";
                                 } else {
                                     NSString *keyString = [path substringWithRange:[result rangeAtIndex:2]];
                                     [keys addObject:keyString];
                                     replacementString = @"([^/]+)";
                                 }

                                 [regexPath replaceCharactersInRange:replacementRange withString:replacementString];
                                 diff += replacementString.length - result.range.length;
                             }];

        path = [NSString stringWithFormat:@"^%@$", regexPath];
    }

    route.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
    if ([keys count] > 0) {
        route.keys = keys;
    }

    return route;
}

- (BOOL)supportsMethod:(NSString *)method {
    return (routes[method] != nil);
}

- (void)handleRoute:(VVRoute *)route withRequest:(VVRouteRequest *)request response:(VVRouteResponse *)response {
    if (route.handler) {
        route.handler(request, response);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [route.target performSelector:route.selector withObject:request withObject:response];
#pragma clang diagnostic pop
    }
}

- (VVRouteResponse *)routeMethod:(NSString *)method withPath:(NSString *)path parameters:(NSDictionary *)params request:(HTTPMessage *)httpMessage connection:(HTTPConnection *)connection {
    NSMutableArray *methodRoutes = routes[method];
    if (methodRoutes == nil)
        return nil;

    for (VVRoute *route in methodRoutes) {
        NSTextCheckingResult *result = [route.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
        if (!result)
            continue;

        // The first range is all of the text matched by the regex.
        NSUInteger captureCount = [result numberOfRanges];

        if (route.keys) {
            // Add the route's parameters to the parameter dictionary, accounting for
            // the first range containing the matched text.
            if (captureCount == [route.keys count] + 1) {
                NSMutableDictionary *newParams = [params mutableCopy];
                NSUInteger index = 1;
                BOOL firstWildcard = YES;
                for (NSString *key in route.keys) {
                    NSString *capture = [path substringWithRange:[result rangeAtIndex:index]];
                    if ([key isEqualToString:@"wildcards"]) {
                        NSMutableArray *wildcards = newParams[key];
                        if (firstWildcard) {
                            // Create a new array and replace any existing object with the same key
                            wildcards = [NSMutableArray array];
                            newParams[key] = wildcards;
                            firstWildcard = NO;
                        }
                        [wildcards addObject:capture];
                    } else {
                        newParams[key] = capture;
                    }
                    index++;
                }
                params = newParams;
            }
        } else if (captureCount > 1) {
            // For custom regular expressions place the anonymous captures in the captures parameter
            NSMutableDictionary *newParams = [params mutableCopy];
            NSMutableArray *captures = [NSMutableArray array];
            for (NSUInteger i = 1; i < captureCount; i++) {
                [captures addObject:[path substringWithRange:[result rangeAtIndex:i]]];
            }
            newParams[@"captures"] = captures;
            params = newParams;
        }

        VVRouteRequest *request = [[VVRouteRequest alloc] initWithHTTPMessage:httpMessage parameters:params];
        VVRouteResponse *response = [[VVRouteResponse alloc] initWithConnection:connection];
        if (!routeQueue) {
            [self handleRoute:route withRequest:request response:response];
        } else {
            // Process the route on the specified queue
            dispatch_sync(routeQueue, ^{
                @autoreleasepool {
                    [self handleRoute:route withRequest:request response:response];
                }
            });
        }
        return response;
    }

    return nil;
}

- (void)setupMIMETypes {
    mimeTypes = [@{@"js": @"application/x-javascript",
            @"gif": @"image/gif",
            @"jpg": @"image/jpeg",
            @"jpeg": @"image/jpeg",
            @"png": @"image/png",
            @"svg": @"image/svg+xml",
            @"tif": @"image/tiff",
            @"tiff": @"image/tiff",
            @"ico": @"image/x-icon",
            @"bmp": @"image/x-ms-bmp",
            @"css": @"text/css",
            @"html": @"text/html",
            @"htm": @"text/html",
            @"txt": @"text/plain",
            @"xml": @"text/xml"} mutableCopy];
}

@end
