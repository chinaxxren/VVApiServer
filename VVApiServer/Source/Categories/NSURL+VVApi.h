
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface NSURL (VVApi)

// 只能用于本地URL
- (NSURL *)localURLProxy;

// 只能用于本地URL
- (NSURL *)localURLProxyWithDelay;

// 只能用于本地URL
//- (NSURL *)proxyWithDelay:(CGFloat)delay;

// 只能用于远程URL
- (NSURL *)remoteURLProxyWithFilter;

@end
