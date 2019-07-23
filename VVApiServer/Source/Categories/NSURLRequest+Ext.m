//
// Created by Tank on 2019-07-23.
// Copyright (c) 2019 Tank. All rights reserved.
//


#import "NSURLRequest+Ext.h"

#import <objc/runtime.h>

#import "VVApiHTTPServer.h"
#import "VVApi.h"

@implementation NSURLRequest (Ext)

+ (void)load {
#if DEBUG
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        [self changeSel:@selector(initWithURL:cachePolicy:timeoutInterval:)
                 newSel:@selector(vv_initWithURL:cachePolicy:timeoutInterval:)];
    });
#endif
}

+ (void)changeSel:(SEL)oldSel newSel:(SEL)newSel {
    Method fromMethod = class_getInstanceMethod([self class], oldSel);
    Method toMethod = class_getInstanceMethod([self class], newSel);
    if (!class_addMethod([self class], newSel, method_getImplementation(toMethod), method_getTypeEncoding(toMethod))) {
        method_exchangeImplementations(fromMethod, toMethod);
    }
}

- (instancetype)vv_initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    if (!URL) {
        return nil;
    }

    VVApiHTTPServer *httpServer = [VVApiHTTPServer share];
    if (httpServer.openApi) {
        VVApi *route = [httpServer findApiWithPath:URL.path];
        if (route) {
            NSString *replace;
            if (route.port) {
                replace = [NSString stringWithFormat:@"127.0.0.1:%@", route.port];
            } else {
                replace = @"127.0.0.1";
            }

            NSString *URLString = [URL absoluteString];
            URLString = [URLString stringByReplacingOccurrencesOfString:URL.host withString:replace];
            URL = [NSURL URLWithString:URLString];
        }
    }

    return [self vv_initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
}

@end
