#import <Foundation/Foundation.h>

#import "VVHTTPServer.h"
#import "VVRouteRequest.h"
#import "VVRouteResponse.h"

typedef void (^VVRequestHandler)(VVRouteRequest *request, VVRouteResponse *response);

@interface VVRouteHTTPServer : VVHTTPServer

@property(nonatomic, readonly) NSDictionary *_defaultHeaderDict;

// Specifies headers that will be set on every response.
// These headers can be overridden by RouteResponses.
- (void)setDefaultHeaders:(NSDictionary *)headers;

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value;

// Returns the dispatch queue on which routes are processed.
// By default this is NULL and routes are processed on CocoaHTTPServer's
// connection queue. You can specify a queue to process routes on, such as
// dispatch_get_main_queue() to process all routes on the main thread.
- (dispatch_queue_t)routeQueue;

- (void)setRouteQueue:(dispatch_queue_t)queue;

- (NSDictionary *)mimeTypes;

- (void)setMIMETypes:(NSDictionary *)types;

- (void)setMIMEType:(NSString *)type forExtension:(NSString *)ext;

- (NSString *)mimeTypeForPath:(NSString *)path;

// Convenience methods. Yes I know, this is Cocoa and we don't use convenience
// methods because typing lengthy primitives over and over and over again is
// elegant with the beauty and the poetry. These are just, you know, here.
- (void)get:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)post:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)put:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)delete:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)handleMethod:(NSString *)method withPath:(NSString *)path withHandler:(VVRequestHandler)handler;

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target selector:(SEL)selector;

- (BOOL)supportsMethod:(NSString *)method;

- (VVRouteResponse *)routeMethod:(NSString *)method
                        withPath:(NSString *)path
                      parameters:(NSDictionary *)params
                         request:(VVHTTPMessage *)httpMessage
                      connection:(VVHTTPConnection *)connection;

@end
