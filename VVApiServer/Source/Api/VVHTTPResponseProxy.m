#import "VVHTTPResponseProxy.h"

@implementation VVHTTPResponseProxy

@synthesize status = _status;

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

// Implement the required VVHTTPResponse methods
- (UInt64)contentLength {
    if (_response) {
        return [_response contentLength];
    } else {
        return 0;
    }
}

- (UInt64)offset {
    if (_response) {
        return [_response offset];
    } else {
        return 0;
    }
}

- (void)setOffset:(UInt64)offset {
    if (_response) {
        [_response setOffset:offset];
    }
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    if (_response) {
        return [_response readDataOfLength:length];
    } else {
        return nil;
    }
}

- (BOOL)isDone {
    if (_response) {
        return [_response isDone];
    } else {
        return YES;
    }
}

// Forward all other invocations to the actual response object
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

