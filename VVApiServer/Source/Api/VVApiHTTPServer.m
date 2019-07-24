
#import "VVApiHTTPServer.h"

#import "VVApiConnection.h"
#import "VVApi.h"

@implementation VVApiHTTPServer {
    NSMutableDictionary *_apiDict;
    NSMutableDictionary *_defaultHeaderDict;
    NSMutableDictionary *_mimeTypeDict;
    dispatch_queue_t _apiQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        connectionClass = [VVApiConnection class];
        _apiDict = [[NSMutableDictionary alloc] init];
        _defaultHeaderDict = [[NSMutableDictionary alloc] init];
        _openApi = YES;

        [self setupMIMETypes];
    }

    return self;
}

+ (instancetype)share {
    static VVApiHTTPServer *httpServer;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        httpServer = [VVApiHTTPServer new];
    });

    return httpServer;
}

- (void)setDefaultHeaders:(NSDictionary *)headers {
    if (headers) {
        _defaultHeaderDict = [headers mutableCopy];
    } else {
        _defaultHeaderDict = [[NSMutableDictionary alloc] init];
    }
}

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value {
    if (!field || !value) {
        return;
    }

    _defaultHeaderDict[field] = value;
}

- (dispatch_queue_t)apiQueue {
    return _apiQueue;
}

- (void)setApiQueue:(dispatch_queue_t)queue {
    _apiQueue = queue;
}

- (NSDictionary *)mimeTypes {
    return _mimeTypeDict;
}

- (void)setMIMETypes:(NSDictionary *)types {
    NSMutableDictionary *newTypes;
    if (types) {
        newTypes = [types mutableCopy];
    } else {
        newTypes = [[NSMutableDictionary alloc] init];
    }

    _mimeTypeDict = newTypes;
}

- (void)setMIMEType:(NSString *)theType forExtension:(NSString *)ext {
    if (!ext || !theType) {
        return;
    }

    _mimeTypeDict[ext] = theType;
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if (!ext || [ext length] < 1)
        return nil;

    return _mimeTypeDict[ext];
}

- (void)get:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"GET" withPath:path withHandler:handler];
}

- (void)get:(NSString *)path port:(NSString *)port withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"GET" port:port withPath:path withHandler:handler];
}

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"POST" withPath:path withHandler:handler];
}

- (void)post:(NSString *)path port:(NSString *)port withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"POST" port:port withPath:path withHandler:handler];
}

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"PUT" withPath:path withHandler:handler];
}

- (void)put:(NSString *)path port:(NSString *)port withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"PUT" port:port withPath:path withHandler:handler];
}

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"DELETE" withPath:path withHandler:handler];
}

- (void)delete:(NSString *)path port:(NSString *)port withHandler:(VVRequestHandler)handler {
    [self handleMethod:@"DELETE" port:port withPath:path withHandler:handler];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:method port:nil withPath:path withHandler:handler];
}

- (void)handleMethod:(NSString *)method port:(NSString *)port withPath:(NSString *)path withHandler:(VVRequestHandler)handler {
    VVApi *api = [self apiWithPath:path];
    api.handler = handler;
    api.port = port;

    [self addApi:api forMethod:method];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target sel:(SEL)sel {
    VVApi *api = [self apiWithPath:path];
    api.target = target;
    api.sel = sel;

    [self addApi:api forMethod:method];
}

- (void)addApi:(VVApi *)api forMethod:(NSString *)method {
    method = [method uppercaseString];
    NSMutableArray *methodApis = _apiDict[method];
    if (!methodApis) {
        methodApis = [NSMutableArray array];
        _apiDict[method] = methodApis;
    }

    [methodApis addObject:api];

    // Define a HEAD api for all GET apis
    if ([method isEqualToString:@"GET"]) {
        [self addApi:api forMethod:@"HEAD"];
    }
}

- (VVApi *)apiWithPath:(NSString *)path {
    VVApi *api = [VVApi new];
    api.path = path;

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
        __block NSInteger diff = 0;
        NSMutableString *regexPath = [NSMutableString stringWithString:path];
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

    api.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
    if ([keys count] > 0) {
        api.keys = keys;
    }

    return api;
}

- (BOOL)supportsMethod:(NSString *)method {
    return _apiDict[method] != nil;
}

- (void)handleApi:(VVApi *)api withRequest:(VVApiRequest *)request response:(VVApiResponse *)response {
    if (api.handler) {
        api.handler(request, response);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [api.target performSelector:api.sel withObject:request withObject:response];
#pragma clang diagnostic pop
    }
}

- (VVApi *)findApiWithPath:(NSString *)path {
    for (NSString *key in [_apiDict allKeys]) {
        for (VVApi *api in _apiDict[key]) {
            NSTextCheckingResult *result = [api.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
            if (result) {
                return api;
            }
        }
    }

    return nil;
}

- (VVApiResponse *)apiMethod:(NSString *)method
                    withPath:(NSString *)path
                  parameters:(NSDictionary *)params
                     request:(VVHTTPMessage *)httpMessage
                  connection:(VVHTTPConnection *)connection {
    NSMutableArray *methodApis = _apiDict[method];
    if (methodApis == nil)
        return nil;

    for (VVApi *api in methodApis) {
        NSTextCheckingResult *result = [api.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
        if (!result)
            continue;

        // The first range is all of the text matched by the regex.
        NSUInteger captureCount = [result numberOfRanges];

        if (api.keys) {
            // Add the api's parameters to the parameter dictionary, accounting for
            // the first range containing the matched text.
            if (captureCount == [api.keys count] + 1) {
                NSMutableDictionary *newParams = [params mutableCopy];
                NSUInteger index = 1;
                BOOL firstWildcard = YES;
                for (NSString *key in api.keys) {
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

        VVApiRequest *request = [[VVApiRequest alloc] initWithHTTPMessage:httpMessage parameters:params];
        VVApiResponse *response = [[VVApiResponse alloc] initWithConnection:connection];
        if (!_apiQueue) {
            [self handleApi:api withRequest:request response:response];
        } else {
            // Process the api on the specified queue
            dispatch_sync(_apiQueue, ^{
                @autoreleasepool {
                    [self handleApi:api withRequest:request response:response];
                }
            });
        }
        return response;
    }

    return nil;
}

- (void)setupMIMETypes {
    _mimeTypeDict = [@{@"js": @"application/x-javascript",
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
            @"txt": @"text/json",
            @"txt": @"application/json",
            @"xml": @"text/xml"} mutableCopy];
}

@end
