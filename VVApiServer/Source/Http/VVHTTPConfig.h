//
// Created by Tank on 2019-07-25.
// Copyright (c) 2019 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VVHTTPServer;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPConfig : NSObject {
    VVHTTPServer __unsafe_unretained *server;
    NSString __strong *documentRoot;
    dispatch_queue_t queue;
}

- (id)initWithServer:(VVHTTPServer *)server documentRoot:(NSString *)documentRoot;

- (id)initWithServer:(VVHTTPServer *)server documentRoot:(NSString *)documentRoot queue:(dispatch_queue_t)q;

@property(nonatomic, unsafe_unretained, readonly) VVHTTPServer *server;
@property(nonatomic, strong, readonly) NSString *documentRoot;
@property(nonatomic, readonly) dispatch_queue_t queue;

@end