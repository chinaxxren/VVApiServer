#import "VVApiResponse.h"

#import "VVHTTPConnection.h"
#import "VVHTTPDataResponse.h"
#import "VVHTTPFileResponse.h"
#import "VVHTTPAsyncFileResponse.h"
#import "VVHTTPResponseProxy.h"

@implementation VVApiResponse {
    NSMutableDictionary *_headers;
    VVHTTPResponseProxy *_proxy;
}

- (id)initWithConnection:(VVHTTPConnection *)theConnection {
    if (self = [super init]) {
        _connection = theConnection;
        _headers = [[NSMutableDictionary alloc] init];
        _proxy = [[VVHTTPResponseProxy alloc] init];
    }
    return self;
}

- (NSObject <VVHTTPResponse> *)response {
    return _proxy.response;
}

- (void)setResponse:(NSObject <VVHTTPResponse> *)response {
    _proxy.response = response;
}

- (NSObject <VVHTTPResponse> *)proxyResponse {
    if (_proxy.response != nil || _proxy.customStatus != 0 || [_headers count] > 0) {
        return _proxy;
    }

    return nil;
}

- (NSInteger)statusCode {
    return _proxy.status;
}

- (void)setStatusCode:(NSInteger)status {
    _proxy.status = status;
}

- (void)setHeader:(NSString *)field value:(NSString *)value {
    _headers[field] = value;
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
        self.response = [[VVHTTPAsyncFileResponse alloc] initWithFilePath:path forConnection:_connection];
    } else {
        self.response = [[VVHTTPFileResponse alloc] initWithFilePath:path forConnection:_connection];
    }
}

@end
