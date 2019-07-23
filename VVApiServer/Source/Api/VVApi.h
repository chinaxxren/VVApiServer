#import <Foundation/Foundation.h>
#import "VVApiHTTPServer.h"

@interface VVApi : NSObject

@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *port;
@property(nonatomic) NSRegularExpression *regex;
@property(nonatomic, copy) VVRequestHandler handler;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL selector;
@property(nonatomic) NSArray *keys;

@end
