
#import "VVApiJSON.h"

@implementation VVApiJSON

+ (id)objectFromJSONString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self objectFromJSONData:data];
}

+ (id)mutableObjectFromJSONString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self mutableObjectFromJSONData:data];
}

+ (id)objectFromJSONData:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
}

+ (id)mutableObjectFromJSONData:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

+ (NSString *)stringWithObject:(id)object {
    NSString *string = nil;
    NSData *data = [self dataWithObject:object];
    if (data) {
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return string;
}

+ (NSData *)dataWithObject:(id)object {
    NSData *data = nil;
    if ([NSJSONSerialization isValidJSONObject:object]) {
        data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    } else {
        NSLog(@"--->>object %@ not a json object", object);
    }
    return data;
}

@end


@implementation NSString (JSONDeserializing)

- (id)toObject {
    return [VVApiJSON objectFromJSONString:self];
}

- (id)toMutableObject {
    return [VVApiJSON mutableObjectFromJSONString:self];
}

@end

@implementation NSData (JSONDeserializing)

- (id)toObject {
    return [VVApiJSON objectFromJSONData:self];
}

- (id)toMutableObject {
    return [VVApiJSON mutableObjectFromJSONData:self];
}

@end

@implementation NSString (JSONSerializing)

- (NSData *)toJSONData {
    return [VVApiJSON dataWithObject:self];
}

- (NSString *)toJSONString {
    return [VVApiJSON stringWithObject:self];
}

@end

@implementation NSArray (JSONSerializing)

- (NSData *)toJSONData {
    return [VVApiJSON dataWithObject:self];
}

- (NSString *)toJSONString {
    return [VVApiJSON stringWithObject:self];
}

@end

@implementation NSDictionary (JSONSerializing)

- (NSData *)toJSONData {
    return [VVApiJSON dataWithObject:self];
}

- (NSString *)toJSONString {
    return [VVApiJSON stringWithObject:self];
}

@end