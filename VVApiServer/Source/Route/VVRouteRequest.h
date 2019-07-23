#import <Foundation/Foundation.h>

@class VVHTTPMessage;

@interface VVRouteRequest : NSObject

@property(nonatomic, readonly) NSDictionary *headers;
@property(nonatomic, readonly) NSDictionary *params;

- (id)initWithHTTPMessage:(VVHTTPMessage *)msg parameters:(NSDictionary *)params;

- (NSString *)header:(NSString *)field;

- (id)param:(NSString *)name;

- (NSString *)method;

- (NSURL *)url;

- (NSData *)body;

@end
