//
// Created by 赵江明 on 2020/5/4.
// Copyright (c) 2020 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VVConnectParams;

@protocol VVAsyncRequestDelegate <NSObject>

- (void)requestFinished;

@end

@interface VVAsyncRequest : NSObject

@property(nonatomic, weak) id <VVAsyncRequestDelegate> delegate;
@property(nonatomic, strong) VVConnectParams *connectParams;

- (void)asyncRequestWithQueue:(dispatch_queue_t)completionQueue;

@end