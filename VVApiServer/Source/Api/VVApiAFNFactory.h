
#import <AFNetworking/AFNetworking.h>

@interface VVApiAFNFactory : NSObject

@property(nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property(nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> *requestSerializer;
@property(nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> *responseSerializer;

+ (AFHTTPSessionManager *)factory;

@end