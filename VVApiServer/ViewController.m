//
//  ViewController.m
//  VVApiServer
//
//  Created by Tank on 2019/7/22.
//  Copyright © 2019 Tank. All rights reserved.
//

#import "ViewController.h"

#import <AFNetworking/AFNetworking.h>

#import "VVApiHTTPServer.h"
#import "VVApiJSON.h"
#import "NSString+VVApi.h"
#import "NSURL+VVApi.h"
#import "PlayerViewController.h"
#import "VVIPHelper.h"

@interface ViewController () {
    VVApiHTTPServer *httpServer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    httpServer = [VVApiHTTPServer share];
    NSString *webPath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"webPath : %@", webPath);
    [httpServer setDocumentRoot:webPath];
    NSError *error = nil;
    if (![httpServer start:&error]) {
        NSLog(@"HTTP server failed to start");
    }

    [self setupApis];
}

- (void)setupApis {
    [httpServer post:@"/upload.html" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        if (response.responseObject) {
            [response respondWithString:[response.responseObject toJSONString]];
        } else {
            NSDictionary *dict = @{@"result": @"upload.html", @"msg": @"success", @"code": @(0)};
            [response respondWithString:[dict toJSONString]];
        }
    }];

    [httpServer post:@"/getWangYiNews" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        if (response.responseObject) {
            [response respondWithString:[response.responseObject toJSONString]];
        } else {
            NSDictionary *dict = @{@"result": @"getWangYiNews", @"msg": @"success", @"code": @(0)};
            [response respondWithString:[dict toJSONString]];
        }
    }];

    [httpServer get:@"/musicRankings" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        if (response.responseObject) {
            [response respondWithString:[response.responseObject toJSONString]];
        } else {
            NSDictionary *dict = @{@"result": @"abcd", @"msg": @"success", @"code": @(0)};
            [response respondWithString:[dict toJSONString]];
        }
    }];

    [httpServer get:@"/errorurl" withHandler:^(VVApiRequest *request, VVApiResponse *response) {

    }];

    [httpServer get:@"/local/news" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"json"];
        NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
        [response respondWithString:jsonString];
    }];

    [httpServer get:@"/video/sync.mp4" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        [response respondWithFile:jsonPath async:NO];
    }];

    [httpServer get:@"/video/async.mp4" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        [response respondWithFile:jsonPath async:YES];
    }];

    [httpServer get:@"/test" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSDictionary *dict = @{@"result": @"test", @"msg": @"success", @"code": @(0)};
        [response respondWithString:[dict toJSONString]];
    }];

    [httpServer get:@"/hello" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSDictionary *dict = @{@"result": @"hello", @"msg": @"success", @"code": @(0)};
        [response respondWithString:[dict toJSONString]];
    }];

    [httpServer get:@"/httperror" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response setStatusCode:405];
        [response setHeader:@"Content-Type" value:@"text/html"];
        [response respondWithString:@"<h1>404 File Not Found</h1>"];
    }];

    [httpServer get:@"/hello/:name" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/hello/%@", [request param:@"name"]]];
    }];

    [httpServer post:@"/form" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:@"/form"];
    }];

    [httpServer post:@"/users/:name" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/users/%@", [request param:@"name"]]];
    }];

    [httpServer post:@"/users/:name/:action" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/users/%@/%@",
                                                               [request param:@"name"],
                                                               [request param:@"action"]]];
    }];

    [httpServer get:@"{^/page/(\\d+)$}" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/page/%@",
                                                               [[request param:@"captures"] objectAtIndex:0]]];
    }];

    [httpServer get:@"/files/*.*" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSArray *wildcards = [request param:@"wildcards"];
        [response respondWithString:[NSString stringWithFormat:@"/files/%@.%@",
                                                               wildcards[0],
                                                               wildcards[1]]];
    }];

    [httpServer post:@"/xml" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSData *bodyData = [request body];
        NSString *xml = [[NSString alloc] initWithBytes:[bodyData bytes] length:[bodyData length] encoding:NSUTF8StringEncoding];

        NSRange tagRange = [xml rangeOfString:@"<greenLevel>"];
        if (tagRange.location != NSNotFound) {
            NSUInteger start = tagRange.location + tagRange.length;
            NSUInteger end = [xml rangeOfString:@"<" options:0 range:NSMakeRange(start, [xml length] - start)].location;
            if (end != NSNotFound) {
                NSString *greenLevel = [xml substringWithRange:NSMakeRange(start, end - start)];
                [response respondWithString:greenLevel];
            }
        }
    }];
}

- (void)afnRequest:(NSString *)method
         urlString:(NSString *)urlString
            params:(NSDictionary *)params
           headers:(NSDictionary *)headers
    sessionManager:(AFHTTPSessionManager *)sessionManager {

    if ([method isEqualToString:VV_API_GET]) {
        [sessionManager GET:urlString
                 parameters:params
                    headers:headers
                   progress:NULL
                    success:^(NSURLSessionDataTask *task, id responseObject) {
                        if ([responseObject isKindOfClass:[NSData class]]) {
                            NSLog(@"reponse->%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                        } else {
                            NSLog(@"reponse->%@", responseObject);
                        }
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    NSLog(@"%@,%s", error, __func__);
                }];
    } else if ([method isEqualToString:VV_API_POST]) {
        [sessionManager POST:urlString
                  parameters:params
                     headers:headers
                    progress:NULL
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         if ([responseObject isKindOfClass:[NSData class]]) {
                             NSLog(@"reponse->%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                         } else {
                             NSLog(@"reponse->%@", responseObject);
                         }
                     } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    NSLog(@"%@,%s", error, __func__);
                }];
    }
}

- (void)nomarlLocalAFNetworkingWithMethod:(NSString *)method path:(NSString *)path isLocal:(BOOL)isLocal isJson:(BOOL)isJson {
    NSString *urlString;
    NSDictionary *params;
    NSDictionary *headers;

    if (isLocal) {
        urlString = [NSString stringWithFormat:@"http://%@:%d", [VVIPHelper ipAddress], httpServer.port];
        urlString = [urlString stringByAppendingString:path];
    } else {
        urlString = @"https://api.apiopen.top";
        params = @{@"page": @1, @"count": @2};
        urlString = [urlString stringByAppendingString:path];
    }

    NSLog(@"Origin URL->%@", urlString);

    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    if (!isJson) {
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    sessionManager.responseSerializer.acceptableContentTypes = [sessionManager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"text/plain"]];

    [self afnRequest:method
           urlString:urlString
              params:params
             headers:headers
      sessionManager:sessionManager];
}

- (void)delayLocalAFNetworkingWithMethod:(NSString *)method path:(NSString *)path isJson:(BOOL)isJson isDelay:(BOOL)isDelay {
    NSString *urlString;
    NSDictionary *params;

    urlString = [NSString stringWithFormat:@"http://%@:%d", [VVIPHelper ipAddress], httpServer.port];
    urlString = [urlString stringByAppendingString:path];

    NSLog(@"Origin URL->%@", urlString);
    if (isDelay) {
        urlString = [urlString localURLProxyWithDelay];
    } else {
        urlString = [urlString localURLProxy];
    }
    NSLog(@"Proxy URL->%@", urlString);

    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    if (!isJson) {
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    sessionManager.responseSerializer.acceptableContentTypes = [sessionManager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"text/plain"]];

    [self afnRequest:method
           urlString:urlString
              params:params
             headers:nil
      sessionManager:sessionManager];
}

- (void)remoteAFNetworkingWithMethod:(NSString *)method path:(NSString *)path isLocal:(BOOL)isLocal isJson:(BOOL)isJson {
    NSString *urlString;
    NSDictionary *params;

    urlString = @"https://api.apiopen.top";
    if ([method isEqualToString:@"POST"]) {
        params = @{@"page": @1, @"count": @2};
    }
    urlString = [urlString stringByAppendingString:path];

    NSLog(@"Origin URL->%@", urlString);
    if (isLocal) {
        urlString = [urlString localURLProxy];
    } else {
        urlString = [urlString remoteURLProxyWithFilter];
    }
    NSLog(@"Proxy URL->%@", urlString);

    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    if (!isJson) {
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    sessionManager.responseSerializer.acceptableContentTypes = [sessionManager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"text/plain"]];
    NSDictionary *headers = @{@"vv_token": @"12345"};

    [self afnRequest:method
           urlString:urlString
              params:params
             headers:headers
      sessionManager:sessionManager];
}

- (void)requestApiWithMethod:(NSString *)method path:(NSString *)path {

    NSString *baseURLString = [NSString stringWithFormat:@"http://%@:%d", [VVIPHelper ipAddress], httpServer.port];;
    NSString *urlString = [baseURLString stringByAppendingString:path];
    NSURL *url = [NSURL URLWithString:urlString];
    url = [url localURLProxyWithDelay];


    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request
                                                       completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                                                           NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes]
                                                                                                               length:[responseData length]
                                                                                                             encoding:NSUTF8StringEncoding];
                                                           NSLog(@"%@", responseString);
                                                       }];

    [sessionDataTask resume];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {

    /******************** found **************************/

    // 本地地址，访问本地服务器读取本地Json,返回当前读取的Json
//    [self nomarlLocalAFNetworkingWithMethod:@"GET" path:@"/local/news" isLocal:YES isJson:YES];
//    [self delayLocalAFNetworkingWithMethod:@"GET" path:@"/local/news" isJson:YES isDelay:NO];
//    [self delayLocalAFNetworkingWithMethod:@"GET" path:@"/local/news" isJson:YES isDelay:YES];

    // 远程地址，访问本地服务器，返回本地自定义结果Json
//    [self remoteAFNetworkingWithMethod:@"POST" path:@"/getWangYiNews" isLocal:YES isJson:YES];

//    [self nomarlLocalAFNetworkingWithMethod:@"GET" path:@"/getWangYiNews" isLocal:NO isJson:YES];

    // 远程地址，访问远程服务器，返回远程结果
//    [self remoteAFNetworkingWithMethod:@"POST" path:@"/getWangYiNews" isLocal:NO isJson:YES];
    [self remoteAFNetworkingWithMethod:@"GET" path:@"/musicRankings" isLocal:NO isJson:YES];
//    [self remoteAFNetworkingWithMethod:@"GET" path:@"/errorurl" isLocal:NO isJson:YES];

//    [self remoteAFNetworkingWithMethod:@"GET" path:@"/musicRankings" isLocal:YES isJson:YES];
//    [self localAFNetworkingWithMethod:@"GET" path:@"/hello?aa=bb&cc=dd" isJson:YES];
//    [self localAFNetworkingWithMethod:@"GET" path:@"/hello/you?aa=bb&cc=dd" isJson:NO];

//    [self requestApiWithMethod:@"GET" path:@"/hello?aa=bb&cc=dd"];
//    [self requestApiWithMethod:@"GET" path:@"/hello/you?aa=bb&cc=dd"];
//    [self requestApiWithMethod:@"GET" path:@"/httperror"];
//    [self requestApiWithMethod:@"GET" path:@"/files/test.txt"];
//    [self requestApiWithMethod:@"GET" path:@"/selector"];
//    [self requestApiWithMethod:@"POST" path:@"/form"];
//    [self requestApiWithMethod:@"POST" path:@"/users/bob"];
//    [self requestApiWithMethod:@"POST" path:@"/users/bob/dosomething"];

    /******************** not found **************************/

//    [self localAFNetworkingWithMethod:@"GET" path:@"/helloworld" isJson:NO];

//    [self requestApiWithMethod:@"GET" path:@"/helloworld"];
//    [self requestApiWithMethod:@"POST" path:@"/hello"];
//    [self requestApiWithMethod:@"POST" path:@"/selector"];
//    [self requestApiWithMethod:@"GET" path:@"/page/a3"];
//    [self requestApiWithMethod:@"GET" path:@"/page/3a"];
//    [self requestApiWithMethod:@"GET" path:@"/form"];

//    [self playLocalVideo:@"/video/sync.mp4"];
//    [self playLocalVideo:@"/video/async.mp4"];
}

- (void)playLocalVideo:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%d%@", [VVIPHelper ipAddress], httpServer.port, path];
    NSLog(@"video->%@", urlString);
    PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithUrl:[NSURL URLWithString:urlString]];
    [self.navigationController pushViewController:playerViewController animated:YES];
}

@end
