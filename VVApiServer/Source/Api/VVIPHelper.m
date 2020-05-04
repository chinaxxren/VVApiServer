
#import "VVIPHelper.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

@implementation VVIPHelper

+ (NSString *)ipAddress {

    static NSString *address = @"localhost";
    if (![address isEqualToString:@"localhost"]) {
        return address;
    }

    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    int success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);

    return address;
}

@end
