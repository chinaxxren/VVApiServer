
#import <Foundation/Foundation.h>

@interface VVApiJSON : NSObject

+ (id)objectFromJSONString:(NSString *)string;

+ (id)mutableObjectFromJSONString:(NSString *)string;

+ (id)objectFromJSONData:(NSData *)data;

+ (id)mutableObjectFromJSONData:(NSData *)data;

+ (NSString *)stringWithObject:(id)object;

+ (NSData *)dataWithObject:(id)object;

@end

@interface NSString (JSONDeserializing)

- (id)toObject;

- (id)toMutableObject;

@end

@interface NSData (JSONDeserializing)

// the nsdata must be utf8 encoded json.
- (id)toObject;

- (id)toMutableObject;

@end

@interface NSString (JSONSerializing)

- (NSData *)toJSONData;

- (NSString *)toJSONString;

@end

@interface NSArray (JSONSerializing)

- (NSData *)toJSONData;

- (NSString *)toJSONString;

@end

@interface NSDictionary (JSONSerializing)

- (NSData *)toJSONData;

- (NSString *)toJSONString;

@end
