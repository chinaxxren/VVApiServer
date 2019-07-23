#import "VVHTTPDataResponse.h"
#import "VVHTTPLogging.h"

#if !__has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_OFF; // | HTTP_LOG_FLAG_TRACE;


@implementation VVHTTPDataResponse

- (id)initWithData:(NSData *)dataParam {
    if ((self = [super init])) {
        VVHTTPLogTrace();

        offset = 0;
        data = dataParam;
    }
    return self;
}

- (void)dealloc {
    VVHTTPLogTrace();

}

- (UInt64)contentLength {
    UInt64 result = (UInt64) [data length];

    VVHTTPLogTrace2(@"%@[%p]: contentLength - %llu", VV_THIS_FILE, self, result);

    return result;
}

- (UInt64)offset {
    VVHTTPLogTrace();

    return offset;
}

- (void)setOffset:(UInt64)offsetParam {
    VVHTTPLogTrace2(@"%@[%p]: setOffset:%lu", VV_THIS_FILE, self, (unsigned long) offset);

    offset = (NSUInteger) offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter {
    VVHTTPLogTrace2(@"%@[%p]: readDataOfLength:%lu", VV_THIS_FILE, self, (unsigned long) lengthParameter);

    NSUInteger remaining = [data length] - offset;
    NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;

    void *bytes = (void *) ([data bytes] + offset);

    offset += length;

    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone {
    BOOL result = (offset == [data length]);

    VVHTTPLogTrace2(@"%@[%p]: isDone - %@", VV_THIS_FILE, self, (result ? @"YES" : @"NO"));

    return result;
}

@end
