#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"

@class VVHTTPConnection;

// Wraps an VVHTTPResponse object to allow setting a custom status code
// without needing to create subclasses of every response.
@interface VVHTTPResponseProxy : NSObject <VVHTTPResponse>

@property(nonatomic) NSObject <VVHTTPResponse> *response;
@property(nonatomic, assign) VVHTTPConnection *connection;
@property(nonatomic, assign) NSInteger status;

- (id)initWithConnection:(VVHTTPConnection *)theConnection;

- (NSInteger)customStatus;

@end
