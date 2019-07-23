#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"

// Wraps an VVHTTPResponse object to allow setting a custom status code
// without needing to create subclasses of every response.
@interface VVHTTPResponseProxy : NSObject <VVHTTPResponse>

@property(nonatomic, assign) NSObject <VVHTTPResponse> *response;
@property(nonatomic, assign) NSInteger status;

- (NSInteger)customStatus;

@end
