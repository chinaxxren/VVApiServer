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

- (void)testApis {

    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    VVApiResponse *response = [httpServer apiMethod:@"GET" withPath:@"/null" parameters:params request:request connection:nil];

    [self verifyApiWithMethod:@"GET" path:@"/hello"];
    [self verifyApiWithMethod:@"GET" path:@"/hello/you"];
    [self verifyApiWithMethod:@"GET" path:@"/page/3"];
    [self verifyApiWithMethod:@"GET" path:@"/files/test.txt"];
    [self verifyApiWithMethod:@"GET" path:@"/selector"];
    [self verifyApiWithMethod:@"POST" path:@"/form"];
    [self verifyApiWithMethod:@"POST" path:@"/users/bob"];
    [self verifyApiWithMethod:@"POST" path:@"/users/bob/dosomething"];

    [self verifyApiNotFoundWithMethod:@"POST" path:@"/hello"];
    [self verifyApiNotFoundWithMethod:@"POST" path:@"/selector"];
    [self verifyApiNotFoundWithMethod:@"GET" path:@"/page/a3"];
    [self verifyApiNotFoundWithMethod:@"GET" path:@"/page/3a"];
    [self verifyApiNotFoundWithMethod:@"GET" path:@"/form"];
}

- (void)testGet {
//    NSString *baseURLString = [NSString stringWithFormat:@"http://127.0.0.1:%d", [httpServer listeningPort]];
    NSString *baseURLString = [NSString stringWithFormat:@"http://www.waqu.com:%d", [httpServer listeningPort]];
    NSString *urlString = [baseURLString stringByAppendingString:@"/hello"];
    NSURL *url = [NSURL URLWithString:urlString];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithURL:url completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes] length:[responseData length] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", responseString);
    }];
    NSLog(@"%@", sessionDataTask.currentRequest.URL);

    [sessionDataTask resume];
}

- (void)verifyApiWithMethod:(NSString *)method path:(NSString *)path {
    
    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    VVApiResponse *response = [httpServer apiMethod:method withPath:path parameters:params request:request connection:nil];
    //STAssertNotNil(response.proxiedResponse, @"Proxied response is nil for %@ %@", method, path);

    NSUInteger length = [response.proxyResponse contentLength];
    NSData *data = [response.proxyResponse readDataOfLength:length];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //STAssertEqualObjects(responseString, path, @"Unexpected response for %@ %@", method, path);
}

- (void)verifyApiNotFoundWithMethod:(NSString *)method path:(NSString *)path {

    NSDictionary *params = [NSDictionary dictionary];
    VVHTTPMessage *request = [[VVHTTPMessage alloc] initEmptyRequest];

    VVApiResponse *response = [httpServer apiMethod:method withPath:path parameters:params request:request connection:nil];
    NSLog(@"Response should have been nil for %@ %@", method, path);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self testApis];
}

@end
