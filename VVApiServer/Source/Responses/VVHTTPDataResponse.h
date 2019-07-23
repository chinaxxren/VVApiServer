#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"


@interface VVHTTPDataResponse : NSObject <VVHTTPResponse> {
    NSUInteger offset;
    NSData *data;
}

- (id)initWithData:(NSData *)data;

@end
