
#import "VVHTTPResponseProxy.h"

#import <CoreGraphics/CoreGraphics.h>

#import "VVHTTPConnection.h"
#import "VVApiHTTPServer.h"
#import "VVApiConfig.h"

@implementation VVHTTPResponseProxy {
    dispatch_queue_t _responseQueue;
    BOOL _readyToSendResponseHeaders;
    CGFloat _timeout;
}

@synthesize status = _status;

- (id)initWithConnection:(VVHTTPConnection *)theConnection {
    if (self = [super init]) {
        _connection = theConnection;
        _responseQueue = dispatch_queue_create("VVHTTPResponseProxy", NULL);
        _readyToSendResponseHeaders = NO;
        _timeout = [VVApiHTTPServer share].apiConfig.timeout;

        if (_timeout > 0) {
            [self doAsyncStuff];
        }
    }

    return self;
}

- (void)doAsyncStuff {
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(concurrentQueue, ^{
        @autoreleasepool {

            [NSThread sleepForTimeInterval:_timeout];
            dispatch_async(_responseQueue, ^{
                @autoreleasepool {
                    [self asyncStuffFinished];
                }
            });
        }
    });
}

- (void)asyncStuffFinished {
    _readyToSendResponseHeaders = YES;

    [_connection responseHasAvailableData:self];
}

- (BOOL)delayResponseHeaders {
    if (_timeout > 0) {
        __block BOOL delayResponseHeaders = NO;
        dispatch_sync(_responseQueue, ^{
            delayResponseHeaders = !_readyToSendResponseHeaders;
        });

        return delayResponseHeaders;
    }

    return NO;
}

- (void)connectionDidClose {
    if (_timeout > 0) {
        dispatch_sync(_responseQueue, ^{
            _connection = nil;
        });
    } else {
        _connection = nil;
    }
}

- (NSInteger)status {
    if (_status != 0) {
        return _status;
    } else if ([_response respondsToSelector:@selector(status)]) {
        return [_response status];
    }

    return 200;
}

- (void)setStatus:(NSInteger)statusCode {
    _status = statusCode;
}

- (NSInteger)customStatus {
    return _status;
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

    if (_timeout > 0) {
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

    if (_timeout > 0) {
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

    if (_timeout > 0) {
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

    if (_timeout > 0) {
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

    if (_timeout > 0) {
        dispatch_sync(_responseQueue, block);
    } else {
        block();
    }

    return isDone;
}

#pragma  Forward all other invocations to the actual response object

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([_response respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:_response];
    } else {
        [super forwardInvocation:invocation];
    }
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector])
        return YES;

    return [_response respondsToSelector:selector];
}

@end

