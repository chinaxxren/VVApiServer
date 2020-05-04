
#import "VVAsyncRequest.h"

#import <AFNetworking/AFHTTPSessionManager.h>

#import "VVApiAFNFactory.h"
#import "VVConnectParams.h"
#import "VVApiConstants.h"
#import "VVApiResponse.h"
#import "VVApiJSON.h"

@interface VVAsyncRequest ()

@property(nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation VVAsyncRequest

- (void)asyncRequestWithQueue:(dispatch_queue_t)completionQueue {
    NSString *method = [self.connectParams method];
    NSString *urlString = [self.connectParams url];
    NSDictionary *headers = [self.connectParams headers];
    NSDictionary *params = [self.connectParams params];

    self.sessionManager = [VVApiAFNFactory factory];
    self.sessionManager.completionQueue = completionQueue;
    for (NSString *key in headers) {
        [self.sessionManager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
    AFHTTPResponseSerializer <AFURLResponseSerialization> *responseSerializer = self.sessionManager.responseSerializer;
    responseSerializer.acceptableContentTypes = [responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"text/plain"]];

    if ([method isEqualToString:VV_API_HEAD]) {
        [self headRequest:urlString params:params];
    } else if ([method isEqualToString:VV_API_GET]) {
        [self getRequest:urlString params:params];
    } else if ([method isEqualToString:VV_API_POST]) {
        [self postRequst:urlString params:params];
    } else if ([method isEqualToString:VV_API_PUT]) {
        [self putRequest:urlString params:params];
    } else if ([method isEqualToString:VV_API_DELETE]) {
        [self deleteRequuest:urlString params:params];
    }
}

- (void)headRequest:(NSString *)urlString params:(NSDictionary *)params {
    VVWeak(self);
    [self.sessionManager HEAD:urlString
                   parameters:params
                      success:^(NSURLSessionDataTask *task) {
                          VVStrong(self);

                          [self requsestSuccess:nil];
                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                VVStrong(self);

                [self requestFail:error response:task.response];
            }];
}

- (void)getRequest:(NSString *)urlString params:(NSDictionary *)params {
    VVWeak(self);
    [self.sessionManager GET:urlString
                  parameters:params
                    progress:NULL
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         VVStrong(self);

                         [self requsestSuccess:responseObject];
                     } failure:^(NSURLSessionDataTask *task, NSError *error) {
                VVStrong(self);

                [self requestFail:error response:task.response];
            }];
}

- (void)postRequst:(NSString *)urlString params:(NSDictionary *)params {
    VVWeak(self);
    [self.sessionManager POST:urlString
                   parameters:params
                     progress:NULL
                      success:^(NSURLSessionDataTask *task, id responseObject) {
                          VVStrong(self);

                          [self requsestSuccess:responseObject];
                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                VVStrong(self);

                [self requestFail:error response:task.response];
            }];
}

- (void)putRequest:(NSString *)urlString params:(NSDictionary *)params {
    VVWeak(self);
    [self.sessionManager PUT:urlString
                  parameters:params
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         VVStrong(self);

                         [self requsestSuccess:responseObject];
                     } failure:^(NSURLSessionDataTask *task, NSError *error) {
                VVStrong(self);

                [self requestFail:error response:task.response];
            }];
}

- (void)deleteRequuest:(NSString *)urlString params:(NSDictionary *)params {
    VVWeak(self);
    [self.sessionManager DELETE:urlString
                     parameters:params
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            VVStrong(self);

                            [self requsestSuccess:responseObject];
                        } failure:^(NSURLSessionDataTask *task, NSError *error) {
                VVStrong(self);

                [self requestFail:error response:task.response];
            }];
}

- (void)requsestSuccess:(id)responseObject {
    self.connectParams.response.responseObject = responseObject;
    [self requestFinished];
}

- (void)requestFail:(NSError *)error response:(NSURLResponse *)response {
    self.connectParams.response.statusCode = ((NSHTTPURLResponse *) response).statusCode;
    [self.connectParams.response respondWithData:[error.userInfo toJSONData]];
    [self requestFinished];
}

- (void)requestFinished {
    if ([self.delegate respondsToSelector:@selector(requestFinished)]) {
        [self.delegate requestFinished];
    }
}

@end
