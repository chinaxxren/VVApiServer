#import "VVRouteResponse.h"

#import "VVHTTPConnection.h"
#import "VVHTTPDataResponse.h"
#import "VVHTTPFileResponse.h"
#import "VVHTTPAsyncFileResponse.h"
#import "VVHTTPResponseProxy.h"

@implementation VVRouteResponse {
    NSMutableDictionary *headers;
    VVHTTPResponseProxy *proxy;
}

@synthesize connection;
@synthesize headers;

- (id)initWithConnection:(VVHTTPConnection *)theConnection {
    if (self = [super init]) {
        connection = theConnection;
        headers = [[NSMutableDictionary alloc] init];
        proxy = [[VVHTTPResponseProxy alloc] init];
    }
    return self;
}

- (NSObject <VVHTTPResponse> *)response {
    return proxy.response;
}

- (void)setResponse:(NSObject <VVHTTPResponse> *)response {
    proxy.response = response;
}

- (NSObject <VVHTTPResponse> *)proxiedResponse {
    if (proxy.response != nil || proxy.customStatus != 0 || [headers count] > 0) {
        return proxy;
    }

    return nil;
}

- (NSInteger)statusCode {
    return proxy.status;
}

- (void)setStatusCode:(NSInteger)status {
    proxy.status = status;
}

- (void)setHeader:(NSString *)field value:(NSString *)value {
    headers[field] = value;
}

- (void)respondWithString:(NSString *)string {
    [self respondWithString:string encoding:NSUTF8StringEncoding];
}

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
    [self respondWithData:[string dataUsingEncoding:encoding]];
}

- (void)respondWithData:(NSData *)data {
    self.response = [[VVHTTPDataResponse alloc] initWithData:data];
}

- (void)respondWithFile:(NSString *)path {
    [self respondWithFile:path async:NO];
}

- (void)respondWithFile:(NSString *)path async:(BOOL)async {
    if (async) {
        self.response = [[VVHTTPAsyncFileResponse alloc] initWithFilePath:path forConnection:connection];
    } else {
        self.response = [[VVHTTPFileResponse alloc] initWithFilePath:path forConnection:connection];
    }
}

@end
