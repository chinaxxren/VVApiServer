#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"


@interface VVHTTPDataResponse : NSObject <VVHTTPResponse> {
    NSUInteger offset;
}

@property(nonatomic, strong) NSData *data;

- (id)initWithData:(NSData *)data;

@end
