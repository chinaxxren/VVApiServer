#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"

@class VVHTTPConnection;
@class VVHTTPResponseProxy;

@interface VVRouteResponse : NSObject

@property(nonatomic, assign, readonly) VVHTTPConnection *connection;
@property(nonatomic, readonly) NSDictionary *headers;
@property(nonatomic, strong) NSObject <VVHTTPResponse> *response;
@property(nonatomic, readonly) NSObject <VVHTTPResponse> *proxiedResponse;
@property(nonatomic) NSInteger statusCode;

- (id)initWithConnection:(VVHTTPConnection *)theConnection;

- (void)setHeader:(NSString *)field value:(NSString *)value;

- (void)respondWithString:(NSString *)string;

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding;

- (void)respondWithData:(NSData *)data;

- (void)respondWithFile:(NSString *)path;

- (void)respondWithFile:(NSString *)path async:(BOOL)async;

@end
