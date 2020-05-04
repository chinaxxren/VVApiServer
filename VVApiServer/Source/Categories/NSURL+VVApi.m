

#import "NSURL+VVApi.h"

#import <Foundation/Foundation.h>
#import "VVApiHTTPServer.h"
#import "VVApi.h"

@implementation NSURL (VVApi)

- (NSURL *)localURLProxy {
    return [self proxyWithDelay:@"0"];;
}

- (NSURL *)localURLProxyWithDelay {
    return [self proxyWithDelay:@"1.0"];
}

- (NSURL *)proxyWithDelay:(NSString *)delay {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:VV_API_LOCAL_DELAY value:delay]];
    urlComponents.queryItems = queryItems;
    return urlComponents.URL;
}

- (NSURL *)remoteURLProxyWithFilter {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:VV_API_IS_REMOTE value:@"1"]];
    urlComponents.queryItems = queryItems;
    return urlComponents.URL;
}

@end
