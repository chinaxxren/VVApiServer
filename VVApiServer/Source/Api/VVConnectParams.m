
#import "VVConnectParams.h"
#import "VVApi.h"


@implementation VVConnectParams

+ (VVConnectParams *)urlParamsWithApi:(VVApi *)api path:(NSString *)path {
    if(!api || !path) {
        return nil;
    }
    
    NSMutableString *url = [NSMutableString new];
    if (api.schema) {
        [url appendString:api.schema];
        [url appendString:@"://"];
    }

    if(api.host) {
        [url appendString:api.host];
    }
    
    if (api.port) {
        [url appendFormat:@":%@", api.port];
    }
    
    [url appendString:path];

    VVConnectParams *params = [VVConnectParams new];
    params.url = [url description];
    params.delay = api.delay;

    return params;
}

@end
