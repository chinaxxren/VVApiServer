
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class VVApi;
@class VVApiRequest;
@class VVApiResponse;

@interface VVConnectParams : NSObject

@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *method;
@property(nonatomic, copy) NSDictionary *headers;
@property(nonatomic, copy) NSDictionary *params;
@property(nonatomic, copy) NSArray *files;
@property(nonatomic, assign) BOOL remote;
@property(nonatomic, assign) CGFloat delay;
@property(nonatomic, weak) VVApi *api;
@property(nonatomic, weak) VVApiResponse *response;
@property(nonatomic, strong) VVApiRequest *request;

+ (VVConnectParams *)urlParamsWithApi:(VVApi *)api path:(NSString *)path;

@end
