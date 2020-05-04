

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@interface NSString (VVApi)

// 只能用于本地URL
- (NSString *)localURLProxy;

// 只能用于本地URL
- (NSString *)localURLProxyWithDelay;

// 只能用于本地URL
//- (NSString *)proxyWithDelay:(CGFloat)delay;

// 只能用于远程URL
- (NSString *)remoteURLProxyWithFilter;

@end
