
#import <Foundation/Foundation.h>

//-----------------------------------------------------------------
// interface MultipartMessageHeaderField
//-----------------------------------------------------------------

@interface MultipartMessageHeaderField : NSObject {
    NSString *_name;
    NSString *_value;
    NSMutableDictionary *_params;
}

@property(strong, readonly) NSString *value;
@property(strong, readonly) NSDictionary *params;
@property(strong, readonly) NSString *name;
@property(strong, readonly) NSString *contentType;

- (id)initWithData:(NSData *)data contentEncoding:(NSStringEncoding)encoding;

- (id)initWithFromData:(NSData *)data contentEncoding:(NSStringEncoding)encoding;

- (void)extractFileType:(char *)bytes length:(NSUInteger)length;

@end
