
#import "VVApiAFNFactory.h"

@implementation VVApiAFNFactory

+ (instancetype)shareManager {
    static VVApiAFNFactory *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });

    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.securityPolicy = [AFSecurityPolicy defaultPolicy];

        // 是否允许无效证书, 默认为NO
        self.securityPolicy.allowInvalidCertificates = YES;

        // 是否校验域名, 默认为YES
        self.securityPolicy.validatesDomainName = NO;
    }

    return self;
}

+ (AFHTTPSessionManager *)factory {
    VVApiAFNFactory *apiAfnFactory = [VVApiAFNFactory shareManager];
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager new];
    sessionManager.securityPolicy = apiAfnFactory.securityPolicy;

    if (apiAfnFactory.requestSerializer) {
        sessionManager.requestSerializer = apiAfnFactory.requestSerializer;
    }

    if (apiAfnFactory.responseSerializer) {
        sessionManager.responseSerializer = apiAfnFactory.responseSerializer;
    }

    return sessionManager;
}

@end
