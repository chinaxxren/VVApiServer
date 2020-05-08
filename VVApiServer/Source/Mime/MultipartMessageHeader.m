//
//  MultipartMessagePart.m
//  HttpServer
//
//  Created by Валерий Гаврилов on 29.03.12.
//  Copyright (c) 2012 LLC "Online Publishing Partners" (onlinepp.ru). All rights reserved.

#import "MultipartMessageHeader.h"

#import "MultipartMessageHeaderField.h"
#import "VVHTTPLogging.h"

//-----------------------------------------------------------------
#pragma mark log level

#ifdef DEBUG
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_WARN;
#else
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_WARN;
#endif

//-----------------------------------------------------------------
// implementation MultipartMessageHeader
//-----------------------------------------------------------------


@implementation MultipartMessageHeader

@synthesize fields = _fields, encoding = _encoding, file = _file;

- (id)initWithData:(NSData *)data formEncoding:(NSStringEncoding)formEncoding {
    if (nil == (self = [super init])) {
        return self;
    }

    _fields = [[NSMutableDictionary alloc] initWithCapacity:1];

    // In case encoding is not mentioned,
    _encoding = contentTransferEncoding_unknown;

    char *bytes = (char *) data.bytes;
    NSUInteger length = data.length;
    int offset = 0;

    // split header into header fields, separated by \r\n
    uint16_t fields_separator = 0x0A0D; // \r\n
    while (offset < length - 2) {

        // the !isspace condition is to support header unfolding
        if ((*(uint16_t *) (bytes + offset) == fields_separator) && ((offset == length - 2) || !(isspace(bytes[offset + 2])))) {
            NSData *fieldData = [NSData dataWithBytesNoCopy:bytes length:offset freeWhenDone:NO];
            MultipartMessageHeaderField *field = [[MultipartMessageHeaderField alloc] initWithData:fieldData contentEncoding:formEncoding];
            if (field) {
                [field extractFileType:bytes + offset length:length - offset];
                _fields[field.name] = field;
                VVHTTPLogVerbose(@"MultipartFormDataParser: Processed Header field '%@'", field.name);
            } else {
                NSString *fieldStr = [[NSString alloc] initWithData:fieldData encoding:NSASCIIStringEncoding];
                VVHTTPLogWarn(@"MultipartFormDataParser: Failed to parse MIME header field. Input ASCII string:%@", fieldStr);
            }

            // move to the next header field
            bytes += offset + 2;
            length -= offset + 2;
            offset = 0;
            continue;
        }
        ++offset;
    }

    if (_fields.count == 0) {
        // it was an empty header.
        // we have to set default values.
        // default header.
        MultipartMessageHeaderField *field = [[MultipartMessageHeaderField alloc] initWithFromData:data contentEncoding:formEncoding];
        if (field) {
            _fields[field.name] = field;
            VVHTTPLogVerbose(@"MultipartFormDataParser: Processed Header field '%@'", field.name);
        }
        _file = NO;
    } else {
        _file = YES;
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", _fields];
}


@end
