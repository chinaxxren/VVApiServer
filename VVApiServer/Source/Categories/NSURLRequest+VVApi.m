//
// Created by 赵江明 on 2020/5/2.
// Copyright (c) 2020 Tank. All rights reserved.
//

#import "NSURLRequest+VVApi.h"

#import <objc/runtime.h>

#import "VVApiHTTPServer.h"
#import "VVApi.h"
#import "VVIPHelper.h"

@implementation NSURLRequest (VVApi)

+ (void)load {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        [self changeSel:@selector(initWithURL:cachePolicy:timeoutInterval:)
                 newSel:@selector(vv_initWithURL:cachePolicy:timeoutInterval:)];
    });
}

+ (void)changeSel:(SEL)originalSel newSel:(SEL)swizzleSel {
    Method originalMethod = class_getInstanceMethod([self class], originalSel);
    Method swizzleMethod = class_getInstanceMethod([self class], swizzleSel);
    BOOL didAddMethod = class_addMethod([self class], originalSel, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (didAddMethod) {
        class_replaceMethod([self class], swizzleSel, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
}

- (instancetype)vv_initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    if (!URL) {
        return nil;
    }

    VVApiHTTPServer *httpServer = [VVApiHTTPServer share];
    if ([httpServer isRunning]) {
        VVApi *api = [httpServer findApiWithPath:URL.path];
        if (api) {
            NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:NO];
            NSArray<NSURLQueryItem *> *queryItems = [urlComponents queryItems];

            BOOL hasFilter = NO;
            for (NSURLQueryItem *item in queryItems) {
                if ([item.name isEqualToString:VV_API_IS_REMOTE] && item.value) {
                    api.remote = [item.value boolValue];
                    hasFilter = YES;
                    break;
                } else if ([item.name isEqualToString:VV_API_LOCAL_DELAY] && item.name) {
                    api.localDelay = [item.value floatValue];
                    hasFilter = YES;
                    break;
                }
            }

            if (!api.host) {
                api.schema = urlComponents.scheme;
                api.host = urlComponents.host;
                api.port = urlComponents.port;
            }

            if (hasFilter) {
                urlComponents.scheme = @"http";
                urlComponents.host = [VVIPHelper ipAddress];
                urlComponents.port = @(httpServer.port);
            }

            URL = urlComponents.URL;
        }
    }

    return [self vv_initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
}

@end
