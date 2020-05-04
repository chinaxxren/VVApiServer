#import "VVApiConnection.h"

#import "VVApiHTTPServer.h"
#import "VVHTTPMessage.h"
#import "VVHTTPConfig.h"
#import "VVApiJSON.h"

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

- (void)processBodyData:(NSData *)postDataChunk {
    BOOL result = [_requestMessage appendData:postDataChunk];
    if (!result) {

    }
}

- (NSObject <VVHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    NSURL *url = [_requestMessage url];
    NSDictionary *headers = [_requestMessage allHeaderFields];

    NSString *query = nil;
    _headerDict = nil;
    NSDictionary *params = nil;
    
    if (url) {
        path = [url path]; // Strip the query string from the path
        
        NSData *data = [_requestMessage body];
        if(data.length > 0) {
            query = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        } else {
            query = [url query];
        }
    
        if (query) {
            params = [self parseParams:query];
        }
    }

    VVApiResponse *response = [_httpServer apiMethod:method
                                            withPath:path
                                             headers:headers
                                          parameters:params
                                             request:_requestMessage
                                          connection:self];
    if (response != nil) {
        _headerDict = response.headers;
        return response;
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
