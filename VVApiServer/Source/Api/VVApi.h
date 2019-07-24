#import <Foundation/Foundation.h>
#import "VVApiHTTPServer.h"

@interface VVApi : NSObject

@property(nonatomic, copy) NSString *path;
@property(nonatomic, assign) NSInteger port;
@property(nonatomic, strong) NSRegularExpression *regex;
@property(nonatomic, copy) VVRequestHandler handler;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL sel;
@property(nonatomic) NSArray *keys;

@end
