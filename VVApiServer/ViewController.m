//
//  ViewController.m
//  VVApiServer
//
//  Created by Tank on 2019/7/22.
//  Copyright © 2019 Tank. All rights reserved.
//

#import "ViewController.h"

#import "VVHTTPMessage.h"

#import "VVApiHTTPServer.h"
#import "VVApiConfig.h"
#import "VVJSONAdapter.h"

@interface ViewController () {
    VVApiHTTPServer *httpServer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    httpServer = [VVApiHTTPServer share];
    [httpServer setPort:80];
    httpServer.apiConfig.timeout = 0.5;

    NSError *error = nil;
    if (![httpServer start:&error]) {
        NSLog(@"HTTP server failed to start");
    }
    [self setupApis];
}

- (void)setupApis {
    [httpServer get:@"/test" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:@"test response"];
    }];

    [httpServer get:@"/hello" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSDictionary *dict = @{@"msg": @"success", @"status": @0, @"json": @"hello"};
        NSString *jsonString = [dict JSONString];
        [response respondWithString:jsonString];
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

        // Green?
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

- (void)requestApiWithMethod:(NSString *)method path:(NSString *)path {
    NSString *baseURLString = [NSString stringWithFormat:@"http://www.waqu.com:%d", [httpServer listeningPort]];
    NSString *urlString = [baseURLString stringByAppendingString:path];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
    }];

    [sessionDataTask resume];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {

    // found
    [self requestApiWithMethod:@"GET" path:@"/hello"];
    [self requestApiWithMethod:@"GET" path:@"/hello/you"];
    [self requestApiWithMethod:@"GET" path:@"/page/3"];
    [self requestApiWithMethod:@"GET" path:@"/files/test.txt"];
    [self requestApiWithMethod:@"GET" path:@"/selector"];
    [self requestApiWithMethod:@"POST" path:@"/form"];
    [self requestApiWithMethod:@"POST" path:@"/users/bob"];
    [self requestApiWithMethod:@"POST" path:@"/users/bob/dosomething"];

    // not found
    [self requestApiWithMethod:@"POST" path:@"/hello"];
    [self requestApiWithMethod:@"POST" path:@"/selector"];
    [self requestApiWithMethod:@"GET" path:@"/page/a3"];
    [self requestApiWithMethod:@"GET" path:@"/page/3a"];
    [self requestApiWithMethod:@"GET" path:@"/form"];
}

@end
