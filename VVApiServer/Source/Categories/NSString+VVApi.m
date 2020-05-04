
#import "NSString+VVApi.h"

#import "VVApiHTTPServer.h"
#import "VVApi.h"
#import "VVIPHelper.h"

@implementation NSString (VVApi)

- (NSString *)localURLProxy {
    return [self proxyWithDelay:@"0"];
}

- (NSString *)localURLProxyWithDelay {
    return [self proxyWithDelay:@"1.0"];
}

- (NSString *)proxyWithDelay:(NSString *)delay {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:VV_API_LOCAL_DELAY value:delay]];
    urlComponents.queryItems = queryItems;
    return urlComponents.string;
}

- (NSString *)remoteURLProxyWithFilter {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:VV_API_IS_REMOTE value:@"1"]];
    urlComponents.queryItems = queryItems;
    return urlComponents.string;
}

@end
