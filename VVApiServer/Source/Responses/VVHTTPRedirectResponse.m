#import "VVHTTPRedirectResponse.h"

#import "VVHTTPLogging.h"

#if !__has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


@implementation HTTPRedirectResponse

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        VVHTTPLogTrace();

        redirectPath = [path copy];
    }
    return self;
}

- (UInt64)contentLength {
    return 0;
}

- (UInt64)offset {
    return 0;
}

- (void)setOffset:(UInt64)offset {
    // Nothing to do
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    VVHTTPLogTrace();

    return nil;
}

- (BOOL)isDone {
    return YES;
}

- (NSDictionary *)httpHeaders {
    VVHTTPLogTrace();

    return @{@"Location": redirectPath};
}

- (NSInteger)status {
    VVHTTPLogTrace();

    return 302;
}

- (void)dealloc {
    VVHTTPLogTrace();

}

@end
