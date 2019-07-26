#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"


@interface HTTPRedirectResponse : NSObject <VVHTTPResponse> {
    NSString *redirectPath;
}

- (id)initWithPath:(NSString *)redirectPath;

@end
