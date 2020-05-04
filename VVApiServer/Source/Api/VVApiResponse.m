#import "VVApiResponse.h"

#import <CoreGraphics/CoreGraphics.h>


#import "VVHTTPConnection.h"
#import "VVHTTPDataResponse.h"
#import "VVHTTPFileResponse.h"
#import "VVConnectParams.h"
#import "VVHTTPLogging.h"
#import "VVApiHTTPServer.h"
#import "VVApi.h"
#import "VVAsyncRequest.h"
#import "VVAsyncFile.h"

static const int httpLogLevel = VV_HTTP_LOG_LEVEL_INFO;

@interface VVApiResponse () <VVAsyncRequestDelegate, VVAsyncFileDelegate> {
    NSMutableDictionary *_headers;
    BOOL _readyToSendResponseHeaders;
    dispatch_queue_t _responseQueue;
}

@property(nonatomic, strong) VVConnectParams *connectParams;
@property(nonatomic, strong) VVAsyncRequest *asyncRequest;

@end

@implementation VVApiResponse

- (void)dealloc {
    VVHTTPLogTrace();
}

- (id)initWithConnection:(VVHTTPConnection *)theConnection connectParams:(VVConnectParams *)connectParams {
    if (self = [super init]) {
        _connection = theConnection;
        _connectParams = connectParams;

        _readyToSendResponseHeaders = NO;
        _headers = [[NSMutableDictionary alloc] init];
        _responseQueue = dispatch_queue_create("vv.http.response.proxy", NULL);
    }

    return self;
}

- (void)serverExcute {
    if (_connectParams.remote) {
        [self doAsyncRequest];
    } else if (_connectParams.delay > 0) {
        [self doAsyncStuff];
        [self handleApi];
    } else {
        [self handleApi];
    }
}

- (void)handleApi {
    VVApi *api = self.connectParams.api;
    if (!api) {
        return;
    }

    if (api.handler) {
        api.handler(self.connectParams.request, self.connectParams.response);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [api.target performSelector:api.sel withObject:self.connectParams.request withObject:self.connectParams.response];
#pragma clang diagnostic pop
    }
}

- (void)doAsyncRequest {
    self.asyncRequest = [VVAsyncRequest new];
    self.asyncRequest.delegate = self;
    self.asyncRequest.connectParams = self.connectParams;
    [self.asyncRequest asyncRequestWithQueue:_responseQueue];
}

- (void)doAsyncStuff {
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(concurrentQueue, ^{
        @autoreleasepool {

            [NSThread sleepForTimeInterval:self.connectParams.delay];
            dispatch_async(_responseQueue, ^{
                @autoreleasepool {
                    [self asyncStuffFinished];
                }
            });
        }
    });
}

#pragma mark -- VVAsyncFileDelegate

- (void)requestFinished {
    [self handleApi];
    [self asyncStuffFinished];
}

- (void)asyncStuffFinished {
    _readyToSendResponseHeaders = YES;

    [self responseHasAvailableData];
}

#pragma mark -- VVAsyncFileDelegate

- (void)responseHasAvailableData {
    [_connection responseHasAvailableData:self];
}

- (void)responseDidAbort {
    [_connection responseDidAbort:self];
}

- (BOOL)hasAsync {
    return self.connectParams.remote || self.connectParams.delay > 0;
}

- (BOOL)filterResponse {
    if (self.connectParams.remote) {
        __block BOOL filterResponse = NO;
        dispatch_sync(_responseQueue, ^{
            filterResponse = !_readyToSendResponseHeaders;
        });

        return filterResponse;
    }

    return NO;
}

- (BOOL)delayResponseHeaders {
    if (self.connectParams.delay > 0) {
        __block BOOL delayResponseHeaders = NO;
        dispatch_sync(_responseQueue, ^{
            delayResponseHeaders = !_readyToSendResponseHeaders;
        });

        return delayResponseHeaders;
    }

    return NO;
}

- (void)connectionDidClose {
    if ([_response respondsToSelector:@selector(connectionDidClose)]) {
        [_response connectionDidClose];
    } else {
        if ([self hasAsync]) {
            dispatch_sync(_responseQueue, ^{
                _connection = nil;
            });
        } else {
            _connection = nil;
        }
    }
}

- (NSInteger)status {
    if (self.statusCode != 0) {
        return self.statusCode;
    } else if ([_response respondsToSelector:@selector(status)]) {
        return [_response status];
    }

    return 200;
}

#pragma Implement the VVHTTPResponse methods

- (UInt64)contentLength {
    __block UInt64 contentLength = 0;
    dispatch_block_t block = ^{
        if (_response) {
            contentLength = [_response contentLength];
        } else {
            contentLength = 0;
        }
    };

    if ([self hasAsync]) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }

    return contentLength;
}

- (UInt64)offset {
    __block UInt64 offset = 0;
    dispatch_block_t block = ^{
        if (_response) {
            offset = [_response offset];
        } else {
            offset = 0;
        }
    };

    if ([self hasAsync]) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }

    return offset;
}

- (void)setOffset:(UInt64)offset {
    dispatch_block_t block = ^{
        if (_response) {
            [_response setOffset:offset];
        }
    };

    if ([self hasAsync]) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    __block NSData *data = nil;
    dispatch_block_t block = ^{
        if (_response) {
            data = [_response readDataOfLength:length];
        }
    };

    if ([self hasAsync]) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }

    return data;
}

- (BOOL)isDone {
    __block BOOL isDone = NO;
    dispatch_block_t block = ^{
        if (_response) {
            isDone = [_response isDone];
        } else {
            isDone = YES;
        }
    };

    if ([self hasAsync]) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }

    return isDone;
}

#pragma mark setter getter

- (void)setHeader:(NSString *)field value:(NSString *)value {
    if (!field) {
        return;
    }

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
        self.response = [[VVAsyncFile alloc] initWithFilePath:path
                                                forConnection:self.connection
                                                     delegate:self];
    } else {
        self.response = [[VVHTTPFileResponse alloc] initWithFilePath:path forConnection:self.connection];
    }
}

@end
