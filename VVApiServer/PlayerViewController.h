//
//  PlayerViewController.h
//  VVApiServer
//
//  Created by 赵江明 on 2020/5/3.
//  Copyright © 2020 Tank. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerViewController : UIViewController

- (instancetype)initWithUrl:(NSURL *)url;

+ (instancetype)controllerWithUrl:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
