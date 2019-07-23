#import <Foundation/Foundation.h>
#import "VVRouteHTTPServer.h"

@interface VVRoute : NSObject

@property(nonatomic) NSRegularExpression *regex;
@property(nonatomic, copy) VVRequestHandler handler;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL selector;
@property(nonatomic) NSArray *keys;

@end
