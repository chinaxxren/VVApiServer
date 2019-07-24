//
// Created by Tank on 2019-07-23.
// Copyright (c) 2019 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VVJSONAdapter : NSObject

+ (id)objectFromJSONString:(NSString *)string;

+ (id)mutableObjectFromJSONString:(NSString *)string;

+ (id)objectFromJSONData:(NSData *)data;

+ (id)mutableObjectFromJSONData:(NSData *)data;

+ (NSString *)stringWithObject:(id)object;

+ (NSData *)dataWithObject:(id)object;

@end

@interface NSString (JSONDeserializing)

- (id)objectFromJSONString;

- (id)mutableObjectFromJSONString;

@end

@interface NSData (JSONDeserializing)

// the nsdata must be utf8 encoded json.
- (id)objectFromJSONData;

- (id)mutableObjectFromJSONData;

@end


@interface NSString (JSONSerializing)

- (NSData *)JSONData;

- (NSString *)JSONString;

@end

@interface NSArray (JSONSerializing)

- (NSData *)JSONData;

- (NSString *)JSONString;

@end

@interface NSDictionary (JSONSerializing)

- (NSData *)JSONData;

- (NSString *)JSONString;

@end
