//
// Created by Tank on 2019-07-22.
// Copyright (c) 2019 Tank. All rights reserved.
//

#import "VVHTTPLogging.h"
#import <objc/runtime.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import <libkern/OSAtomic.h>


@implementation VVHTTPLogging

+ (void)vv_log:(int)level format:(NSString *)format, ... {
    if(!format) {
        return;
    }
    
    va_list args;

    va_start(args, format);
    
    NSString *logString = [[NSString alloc] initWithFormat:format arguments:args];

    va_end(args);
    
//    NSLog(@"level->%d,%@",level,logString);
}

@end
