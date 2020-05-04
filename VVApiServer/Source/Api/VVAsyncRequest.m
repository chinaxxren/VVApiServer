
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

    AFHTTPResponseSerializer <AFURLResponseSerialization> *responseSerializer = self.sessionManager.responseSerializer;
    responseSerializer.acceptableContentTypes = [responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"text/plain"]];

    VVWeak(self);
    [self.sessionManager dataTaskWithHTTPMethod:method
                                      URLString:urlString
                                     parameters:params
                                        headers:headers
                                 uploadProgress:NULL
                               downloadProgress:NULL
                                        success:^(NSURLSessionDataTask *task, id responseObject) {
                                            VVStrong(self);
                                            [self requsestSuccess:nil];
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
