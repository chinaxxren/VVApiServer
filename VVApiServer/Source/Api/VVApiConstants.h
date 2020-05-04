//
// Created by 赵江明 on 2020/5/2.
// Copyright (c) 2020 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VVApiRequest;
@class VVApiResponse;

#define VVWeak(o) __weak typeof(self) vvwo = o;
#define VVStrong(o) __strong typeof(self) o = vvwo;

typedef void (^VVRequestHandler)(VVApiRequest *request, VVApiResponse *response);

@interface VVApiConstants : NSObject

extern NSString *const VV_API_IS_REMOTE;
extern NSString *const VV_API_LOCAL_DELAY;

extern NSString *const VV_API_GET;
extern NSString *const VV_API_POST;
extern NSString *const VV_API_HEAD;
extern NSString *const VV_API_PUT;
extern NSString *const VV_API_DELETE;

@end
