#import <Foundation/Foundation.h>

#import "VVHTTPServer.h"
#import "VVApiRequest.h"
#import "VVApiResponse.h"
#import "VVApiConstants.h"

@class VVApi;

@interface VVApiHTTPServer : VVHTTPServer

@property(nonatomic, readonly) NSDictionary *defaultHeaderDict;

+ (instancetype)share;

// Specifies headers that will be set on every response.
// These headers can be overridden by ApiResponses.
- (void)setDefaultHeaders:(NSDictionary *)headers;

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value;

- (NSDictionary *)mimeTypes;

- (void)setMIMETypes:(NSDictionary *)types;

- (void)setMIMEType:(NSString *)type forExtension:(NSString *)ext;

- (NSString *)mimeTypeForPath:(NSString *)path;

- (void)get:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target sel:(SEL)sel;

- (BOOL)supportsMethod:(NSString *)method;

- (VVApi *)findApiWithPath:(NSString *)path;

- (VVApiResponse *)apiMethod:(NSString *)method
                    withPath:(NSString *)path
                     headers:(NSDictionary *)headers
                  parameters:(NSDictionary *)params
                       files:(NSArray *)files
                     request:(VVHTTPMessage *)httpMessage
                  connection:(VVHTTPConnection *)connection;

@end
