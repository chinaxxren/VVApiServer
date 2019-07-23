//
// Created by Tank on 2019-07-23.
// Copyright (c) 2019 Tank. All rights reserved.
//


#import "NSString+Ext.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Ext)

- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash uppercaseString];
}

@end