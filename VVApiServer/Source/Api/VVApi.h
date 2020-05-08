
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "VVApiHTTPServer.h"

@interface VVApi : NSObject

@property(nonatomic, copy) NSString *schema;
@property(nonatomic, copy) NSString *host;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *method;
@property(nonatomic, copy) NSNumber *port;
@property(nonatomic, strong) NSRegularExpression *regex;
@property(nonatomic, copy) VVRequestHandler handler;
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL sel;
@property(nonatomic) NSArray *keys;
@property(nonatomic, assign) CGFloat delay;

+ (VVApi *)apiWithPath:(NSString *)path;

@end
