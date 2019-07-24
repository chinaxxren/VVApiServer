//
// Created by Tank on 2019-07-23.
// Copight (c) 2019 Tank. All rights reserved.
//

#import "VVJSONAdapter.h"

@implementation VVJSONAdapter

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

- (id)objectFromJSONString {
    return [VVJSONAdapter objectFromJSONString:self];
}

- (id)mutableObjectFromJSONString {
    return [VVJSONAdapter mutableObjectFromJSONString:self];
}

@end

@implementation NSData (JSONDeserializing)

- (id)objectFromJSONData {
    return [VVJSONAdapter objectFromJSONData:self];
}

- (id)mutableObjectFromJSONData {
    return [VVJSONAdapter mutableObjectFromJSONData:self];
}

@end


@implementation NSString (JSONSerializing)

- (NSData *)JSONData {
    return [VVJSONAdapter dataWithObject:self];
}

- (NSString *)JSONString {
    return [VVJSONAdapter stringWithObject:self];
}

@end

@implementation NSArray (JSONSerializing)

- (NSData *)JSONData {
    return [VVJSONAdapter dataWithObject:self];
}

- (NSString *)JSONString {
    return [VVJSONAdapter stringWithObject:self];
}

@end

@implementation NSDictionary (JSONSerializing)

- (NSData *)JSONData {
    return [VVJSONAdapter dataWithObject:self];
}

- (NSString *)JSONString {
    return [VVJSONAdapter stringWithObject:self];
}

@end