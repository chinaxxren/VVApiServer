//
//  ViewController.m
//  VVApiServer
//
//  Created by Tank on 2019/7/22.
//  Copyright © 2019 Tank. All rights reserved.
//


#import "ViewController.h"

#import "VVHTTPMessage.h"

#import "VVRouteHTTPServer.h"

@interface ViewController () {
    VVRouteHTTPServer *http;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    http = [[VVRouteHTTPServer alloc] init];
    [http setPort:80];
    NSError *error = nil;
    if (![http start:&error]) {
        NSLog(@"HTTP server failed to start");
    }
    [self setupRoutes];
}

- (void)setupRoutes {
    [http get:@"/hello" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:@"hello wold !"];
    }];

    [http get:@"/hello/:name" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/hello/%@", [request param:@"name"]]];
    }];

    [http post:@"/form" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:@"/form"];
    }];

    [http post:@"/users/:name" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/users/%@", [request param:@"name"]]];
    }];

    [http post:@"/users/:name/:action" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/users/%@/%@",
                                                               [request param:@"name"],
                                                               [request param:@"action"]]];
    }];

    [http get:@"{^/page/(\\d+)$}" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/page/%@",
                                                               [[request param:@"captures"] objectAtIndex:0]]];
    }];

    [http get:@"/files/*.*" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
        NSArray *wildcards = [request param:@"wildcards"];
        [response respondWithString:[NSString stringWithFormat:@"/files/%@.%@",
                                                               wildcards[0],
                                                               wildcards[1]]];
    }];

    [http handleMethod:@"GET" withPath:@"/selector" target:self selector:@selector(handleSelectorRequest:withResponse:)];

    [http post:@"/xml" withHandler:^(VVRouteRequest *request, VVRouteResponse *response) {
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

- (void)handleSelectorRequest:(VVRouteRequest *)request withResponse:(VVRouteResponse *)response {
    [response respondWithString:@"/selector"];
}


- (void)testRoutes {
    VVRouteResponse *response;
    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    response = [http routeMethod:@"GET" withPath:@"/null" parameters:params request:request connection:nil];

    [self verifyRouteWithMethod:@"GET" path:@"/hello"];
    [self verifyRouteWithMethod:@"GET" path:@"/hello/you"];
    [self verifyRouteWithMethod:@"GET" path:@"/page/3"];
    [self verifyRouteWithMethod:@"GET" path:@"/files/test.txt"];
    [self verifyRouteWithMethod:@"GET" path:@"/selector"];
    [self verifyRouteWithMethod:@"POST" path:@"/form"];
    [self verifyRouteWithMethod:@"POST" path:@"/users/bob"];
    [self verifyRouteWithMethod:@"POST" path:@"/users/bob/dosomething"];

    [self verifyRouteNotFoundWithMethod:@"POST" path:@"/hello"];
    [self verifyRouteNotFoundWithMethod:@"POST" path:@"/selector"];
    [self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/a3"];
    [self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/3a"];
    [self verifyRouteNotFoundWithMethod:@"GET" path:@"/form"];
}

- (void)testPost {
    NSString *xmlString = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                          "<greenLevel>supergreen</greenLevel>";

    [self verifyMethod:@"POST" path:@"/xml" contentType:@"text/xml" inputString:xmlString responseString:@"supergreen"];
}

- (void)testGet {
    NSString *baseURLString = [NSString stringWithFormat:@"http://127.0.0.1:%d", [http listeningPort]];

    NSString *urlString = [baseURLString stringByAppendingString:@"/hello"];
    NSURL *url = [NSURL URLWithString:urlString];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithURL:url completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
    }];
    [sessionDataTask resume];
}


- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path {
    VVRouteResponse *response;
    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    response = [http routeMethod:method withPath:path parameters:params request:request connection:nil];
    //STAssertNotNil(response.proxiedResponse, @"Proxied response is nil for %@ %@", method, path);

    NSUInteger length = [response.proxiedResponse contentLength];
    NSData *data = [response.proxiedResponse readDataOfLength:length];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //STAssertEqualObjects(responseString, path, @"Unexpected response for %@ %@", method, path);
}

- (void)verifyRouteNotFoundWithMethod:(NSString *)method path:(NSString *)path {
    VVRouteResponse *response;
    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    response = [http routeMethod:method withPath:path parameters:params request:request connection:nil];
    NSLog(@"Response should have been nil for %@ %@", method, path);
}

- (void)verifyMethod:(NSString *)method path:(NSString *)path contentType:(NSString *)contentType inputString:(NSString *)inputString responseString:(NSString *)expectedResponseString {
    NSError *error = nil;
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding];

    NSString *baseURLString = [NSString stringWithFormat:@"http://127.0.0.1:%d", [http listeningPort]];

    NSString *urlString = [baseURLString stringByAppendingString:path];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%ld", [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];

    NSURLResponse *response;
    NSHTTPURLResponse *httpResponse;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    httpResponse = (NSHTTPURLResponse *) response;

    NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self testGet];
}

@end
