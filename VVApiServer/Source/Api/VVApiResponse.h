#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"

@class VVHTTPConnection;
@class VVHTTPResponseProxy;
@class VVConnectParams;

@interface VVApiResponse : NSObject <VVHTTPResponse>

@property(nonatomic, readonly) NSDictionary *headers;
@property(nonatomic, strong) NSObject <VVHTTPResponse> *response;
@property(nonatomic, strong) id responseObject;
@property(nonatomic, strong) NSError *error;
@property(nonatomic, assign) VVHTTPConnection *connection;
@property(nonatomic, assign) NSInteger statusCode;

- (id)initWithConnection:(VVHTTPConnection *)theConnection connectParams:(VVConnectParams *)connectParams;

- (void)serverExcute;

- (NSInteger)status;

- (void)doAsyncRequest;

- (void)doAsyncStuff;

- (void)handleApi;

- (void)setHeader:(NSString *)field value:(NSString *)value;

- (void)respondWithString:(NSString *)string;

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding;

- (void)respondWithData:(NSData *)data;

- (void)respondWithFile:(NSString *)path;

- (void)respondWithFile:(NSString *)path async:(BOOL)async;

@end
