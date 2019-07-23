#import "VVApiConnection.h"

#import "VVApiHTTPServer.h"
#import "VVHTTPMessage.h"
#import "VVHTTPResponseProxy.h"

@implementation VVApiConnection {
    __weak VVApiHTTPServer *_httpServer;
    NSDictionary *_headerDict;
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
        NSAssert([config.server isKindOfClass:[VVApiHTTPServer class]],
                @"A VVApiConnection is being used with a server that is not a VVApiHTTPServer");

        _httpServer = (VVApiHTTPServer *) config.server;
    }
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    if ([_httpServer supportsMethod:method])
        return YES;

    return [super supportsMethod:method atPath:path];
}

- (BOOL)shouldHandleRequestForMethod:(NSString *)method atPath:(NSString *)path {
    // The default implementation is strict about the use of Content-Length. Either
    // a given method + path combination must *always* include data or *never*
    // include data. The routing connection is lenient, a POST that sometimes does
    // not include data or a GET that sometimes does is fine. It is up to the api
    // implementations to decide how to handle these situations.
    return YES;
}

- (void)processBodyData:(NSData *)postDataChunk {
    BOOL result = [request appendData:postDataChunk];
    if (!result) {
        // TODO: Log
    }
}

- (NSObject <VVHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    NSURL *url = [request url];
    NSString *query = nil;
    NSDictionary *params = [NSDictionary dictionary];
    _headerDict = nil;

    if (url) {
        path = [url path]; // Strip the query string from the path
        query = [url query];
        if (query) {
            params = [self parseParams:query];
        }
    }

    VVApiResponse *response = [_httpServer apiMethod:method withPath:path parameters:params request:request connection:self];
    if (response != nil) {
        _headerDict = response.headers;
        return response.proxyResponse;
    }

    // Set a MIME type for static files if possible
    NSObject <VVHTTPResponse> *staticResponse = [super httpResponseForMethod:method URI:path];
    if (staticResponse && [staticResponse respondsToSelector:@selector(filePath)]) {
        NSString *mimeType = [_httpServer mimeTypeForPath:[staticResponse performSelector:@selector(filePath)]];
        if (mimeType) {
            _headerDict = @{@"Content-Type": mimeType};
        }
    }

    return staticResponse;
}

- (void)responseHasAvailableData:(NSObject <VVHTTPResponse> *)sender {
    VVHTTPResponseProxy *proxy = (VVHTTPResponseProxy *) httpResponse;
    if (proxy.response == sender) {
        [super responseHasAvailableData:httpResponse];
    }
}

- (void)responseDidAbort:(NSObject <VVHTTPResponse> *)sender {
    VVHTTPResponseProxy *proxy = (VVHTTPResponseProxy *) httpResponse;
    if (proxy.response == sender) {
        [super responseDidAbort:httpResponse];
    }
}

- (void)setHeadersForResponse:(VVHTTPMessage *)response isError:(BOOL)isError {
    [_httpServer.defaultHeaderDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
        [response setHeaderField:field value:value];
    }];

    if (_headerDict && !isError) {
        [_headerDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
            [response setHeaderField:field value:value];
        }];
    }

    // Set the connection header if not already specified
    NSString *connection = [response headerField:@"Connection"];
    if (!connection) {
        connection = [self shouldDie] ? @"close" : @"keep-alive";
        [response setHeaderField:@"Connection" value:connection];
    }
}

- (NSData *)preprocessResponse:(VVHTTPMessage *)response {
    [self setHeadersForResponse:response isError:NO];
    return [super preprocessResponse:response];
}

- (NSData *)preprocessErrorResponse:(VVHTTPMessage *)response {
    [self setHeadersForResponse:response isError:YES];
    return [super preprocessErrorResponse:response];
}

- (BOOL)shouldDie {
    __block BOOL shouldDie = [super shouldDie];

    // Allow custom headers to determine if the connection should be closed
    if (!shouldDie && _headerDict) {
        [_headerDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
            if ([field caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
                if ([value caseInsensitiveCompare:@"close"] == NSOrderedSame) {
                    shouldDie = YES;
                }
                *stop = YES;
            }
        }];
    }

    return shouldDie;
}

@end
