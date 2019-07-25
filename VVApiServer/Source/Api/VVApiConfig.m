//
// Created by Tank on 2019-07-25.
// Copyright (c) 2019 Tank. All rights reserved.
//

#import "VVApiConfig.h"

@interface VVApiConfig ()

@end

@implementation VVApiConfig

- (id)init {
    if (self = [super init]) {
        [self setup];
    }

    return self;
}

- (void)setup {
    self.openApi = YES;
    self.timeout = 1.0f;
}

@end