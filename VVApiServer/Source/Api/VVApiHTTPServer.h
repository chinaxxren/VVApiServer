#import <Foundation/Foundation.h>

#import "VVHTTPServer.h"
#import "VVApiRequest.h"
#import "VVApiResponse.h"

typedef void (^VVRequestHandler)(VVApiRequest *request, VVApiResponse *response);

@class VVApi;

@interface VVApiHTTPServer : VVHTTPServer

@property(nonatomic, assign) BOOL openApi;
@property(nonatomic, readonly) NSDictionary *defaultHeaderDict;

+ (instancetype)share;

// Specifies headers that will be set on every response.
// These headers can be overridden by RouteResponses.
- (void)setDefaultHeaders:(NSDictionary *)headers;

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value;

- (dispatch_queue_t)apiQueue;

- (void)setApiQueue:(dispatch_queue_t)queue;

- (NSDictionary *)mimeTypes;

- (void)setMIMETypes:(NSDictionary *)types;

- (void)setMIMEType:(NSString *)type forExtension:(NSString *)ext;

- (NSString *)mimeTypeForPath:(NSString *)path;

// Convenience methods. Yes I know, this is Cocoa and we don't use convenience
// methods because typing lengthy primitives over and over and over again is
// elegant with the beauty and the poetry. These are just, you know, here.
- (void)get:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)get:(NSString *)path port:(NSInteger )port withHandler:(VVRequestHandler)handler;

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)post:(NSString *)path port:(NSInteger )port withHandler:(VVRequestHandler)handler;

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)put:(NSString *)path port:(NSInteger )port withHandler:(VVRequestHandler)handler;

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)delete:(NSString *)path port:(NSInteger )port withHandler:(VVRequestHandler)handler;

- (void)handleMethod:(NSString *)method port:(NSInteger )port withPath:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target sel:(SEL)sel;

- (BOOL)supportsMethod:(NSString *)method;

- (VVApi *)findApiWithPath:(NSString *)path;

- (VVApiResponse *)apiMethod:(NSString *)method
                    withPath:(NSString *)path
                  parameters:(NSDictionary *)params
                     request:(VVHTTPMessage *)httpMessage
                  connection:(VVHTTPConnection *)connection;

@end
