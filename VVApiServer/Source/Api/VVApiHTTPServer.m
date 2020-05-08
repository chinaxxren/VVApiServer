
#import "VVApiHTTPServer.h"

#import "VVApiConnection.h"
#import "VVApi.h"
#import "VVConnectParams.h"
#import "VVApiConstants.h"
#import "VVHTTPMessage.h"
#import "VVIPHelper.h"

@implementation VVApiHTTPServer {
    NSMutableDictionary *_apiDict;
    NSMutableDictionary *_defaultHeaderDict;
    NSMutableDictionary *_mimeTypeDict;
}

- (instancetype)init {
    if (self = [super init]) {
        connectionClass = [VVApiConnection class];
        _apiDict = [NSMutableDictionary new];
        _defaultHeaderDict = [NSMutableDictionary new];

        [self setup];
    }

    return self;
}

- (void)setup {
    [self setupMIMETypes];
    [self setType:@"_http._tcp."];
    [self setPort:9527];
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
        _defaultHeaderDict = [NSMutableDictionary new];
    }
}

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value {
    if (!field || !value) {
        return;
    }

    _defaultHeaderDict[field] = value;
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
    [self handleMethod:VV_API_GET withPath:path withHandler:handler];
}

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:VV_API_POST withPath:path withHandler:handler];
}

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:VV_API_PUT withPath:path withHandler:handler];
}

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler {
    [self handleMethod:VV_API_DELETE withPath:path withHandler:handler];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path withHandler:(VVRequestHandler)handler {
    VVApi *api = [VVApi apiWithPath:path];
    api.handler = handler;
    api.method = method;
    api.port = @(self.port);

    [self addApi:api forMethod:method];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target sel:(SEL)sel {
    VVApi *api = [VVApi apiWithPath:path];
    api.target = target;
    api.sel = sel;
    api.method = method;
    api.port = @(self.port);

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

- (BOOL)supportsMethod:(NSString *)method {
    return _apiDict[method] != nil;
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
                     headers:(NSDictionary *)headers
                  parameters:(NSDictionary *)params
                       files:(NSArray *)files
                     request:(VVHTTPMessage *)httpMessage
                  connection:(VVHTTPConnection *)connection {
    NSMutableArray *methodApis = _apiDict[method];
    if (methodApis == nil) {
        return nil;
    }

    VVConnectParams *connectParams;
    for (VVApi *api in methodApis) {
        NSTextCheckingResult *result = [api.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
        if (!result) {
            continue;
        }

        connectParams = [VVConnectParams urlParamsWithApi:api path:[httpMessage url].path];
        connectParams.method = method;
        connectParams.headers = headers;
        connectParams.params = params;
        connectParams.files = files;
        connectParams.api = api;

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
        VVApiResponse *response = [[VVApiResponse alloc] initWithConnection:connection connectParams:connectParams];
        connectParams.request = request;
        connectParams.response = response;
        [response serverExcute];

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
