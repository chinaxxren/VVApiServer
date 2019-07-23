#import "VVApiRequest.h"

#import "VVHTTPMessage.h"

@implementation VVApiRequest {
    VVHTTPMessage *_message;
}

- (id)initWithHTTPMessage:(VVHTTPMessage *)msg parameters:(NSDictionary *)parameters {
    if (self = [super init]) {
        _params = parameters;
        _message = msg;
    }
    return self;
}

- (NSDictionary *)headers {
    return [_message allHeaderFields];
}

- (NSString *)header:(NSString *)field {
    return [_message headerField:field];
}

- (id)param:(NSString *)name {
    return _params[name];
}

- (NSString *)method {
    return [_message method];
}

- (NSURL *)url {
    return [_message url];
}

- (NSData *)body {
    return [_message body];
}

- (NSString *)description {
    NSData *data = [_message messageData];
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end
