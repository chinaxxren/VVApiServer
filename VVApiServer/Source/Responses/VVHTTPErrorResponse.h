#import "VVHTTPResponse.h"

@interface VVHTTPErrorResponse : NSObject <VVHTTPResponse> {
    NSInteger _status;
}

- (id)initWithErrorCode:(int)httpErrorCode;

@end
