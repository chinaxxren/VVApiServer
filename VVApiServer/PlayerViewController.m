//
//  PlayerViewController.m
//  VVApiServer
//
//  Created by 赵江明 on 2020/5/3.
//  Copyright © 2020 Tank. All rights reserved.
//

#import "PlayerViewController.h"

#import <AVKit/AVKit.h>

@interface PlayerViewController ()

@property(nonatomic, strong) AVPlayerViewController *playerViewController;
@property(nonatomic, strong) NSURL *url;

@end

@implementation PlayerViewController

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        self.url = url;
    }

    return self;
}

+ (instancetype)controllerWithUrl:(NSURL *)url {
    return [[self alloc] initWithUrl:url];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = [AVPlayer playerWithURL:self.url];
    self.playerViewController.view.frame = self.view.bounds;
    self.playerViewController.showsPlaybackControls = YES;
    //开启这个播放的时候支持（全屏）横竖屏哦
    //self.playerVC.entersFullScreenWhenPlaybackBegins = YES;
    //开启这个所有 item 播放完毕可以退出全屏
    //self.playerVC.exitsFullScreenWhenPlaybackEnds = YES;
    [self.view addSubview:self.playerViewController.view];

    if (self.playerViewController.readyForDisplay) {
        [self.playerViewController.player play];
    }
}

@end
