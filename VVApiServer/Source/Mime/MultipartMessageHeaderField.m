
#import "MultipartMessageHeaderField.h"

#import "VVHTTPLogging.h"

//-----------------------------------------------------------------
#pragma mark log level

#ifdef DEBUG
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_WARN;
#else
static const int httpLogLevel = VV_HTTP_LOG_LEVEL_WARN;
#endif


// helpers
int findChar(const char *str, NSUInteger length, char c);

NSString *extractParamValue(const char *bytes, NSUInteger length, NSStringEncoding encoding);

NSString *extractFormValue(const char *bytes, NSUInteger length, NSStringEncoding encoding);

//-----------------------------------------------------------------
// interface MultipartMessageHeaderField (private)
//-----------------------------------------------------------------


@interface MultipartMessageHeaderField (private)

- (BOOL)parseHeaderValueBytes:(char *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;

@end


//-----------------------------------------------------------------
// implementation MultipartMessageHeaderField
//-----------------------------------------------------------------

@implementation MultipartMessageHeaderField

@synthesize name = _name, value = _value, contentType = _contentType;

- (id)initWithData:(NSData *)data contentEncoding:(NSStringEncoding)encoding {
    _params = [[NSMutableDictionary alloc] initWithCapacity:1];

    char *bytes = (char *) data.bytes;
    NSUInteger length = data.length;

    int separatorOffset = findChar(bytes, length, ':');
    if ((-1 == separatorOffset) || (separatorOffset >= length - 2)) {
        VVHTTPLogError(@"MultipartFormDataParser: Bad format.No colon in field header.");
        // tear down
        return nil;
    }

    // header name is always ascii encoded;
    _name = [[NSString alloc] initWithBytes:bytes length:separatorOffset encoding:NSASCIIStringEncoding];
    if (nil == _name) {
        VVHTTPLogError(@"MultipartFormDataParser: Bad MIME header name.");
        // tear down
        return nil;
    }

    // skip the separator and the next ' ' symbol
    bytes += separatorOffset + 2;
    length -= separatorOffset + 2;

    separatorOffset = findChar(bytes, length, ';');
    if (separatorOffset == -1) {
        // couldn't find ';', means we don't have extra params here.
        _value = [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];

        if (nil == _value) {
            VVHTTPLogError(@"MultipartFormDataParser: Bad MIME header value for header name: '%@'", _name);
            // tear down
            return nil;
        }
        return self;
    }

    _value = [[NSString alloc] initWithBytes:bytes length:separatorOffset encoding:encoding];
    VVHTTPLogVerbose(@"MultipartFormDataParser: Processing  header field '%@' : '%@'", _name, _value);
    // skipe the separator and the next ' ' symbol
    bytes += separatorOffset + 2;
    length -= separatorOffset + 2;

    // parse the "params" part of the header
    if (![self parseHeaderValueBytes:bytes length:length encoding:encoding]) {
        NSString *paramsStr = [[NSString alloc] initWithBytes:bytes length:length encoding:NSASCIIStringEncoding];
        VVHTTPLogError(@"MultipartFormDataParser: Bad params for header with name '%@' and value '%@'", _name, _value);
        VVHTTPLogError(@"MultipartFormDataParser: Params str: %@", paramsStr);

        return nil;
    }
    return self;
}

- (id)initWithFromData:(NSData *)data contentEncoding:(NSStringEncoding)encoding {
    _params = [[NSMutableDictionary alloc] initWithCapacity:1];

    char *bytes = (char *) data.bytes;
    NSUInteger length = data.length;

    int separatorOffset = findChar(bytes, length, ':');
    if ((-1 == separatorOffset) || (separatorOffset >= length - 2)) {
        VVHTTPLogError(@"MultipartFormDataParser: Bad format.No colon in field header.");
        // tear down
        return nil;
    }

    // header name is always ascii encoded;
    _name = [[NSString alloc] initWithBytes:bytes length:separatorOffset encoding:NSASCIIStringEncoding];
    if (nil == _name) {
        VVHTTPLogError(@"MultipartFormDataParser: Bad MIME header name.");
        // tear down
        return nil;
    }

    // skip the separator and the next ' ' symbol
    bytes += separatorOffset + 2;
    length -= separatorOffset + 2;

    separatorOffset = findChar(bytes, length, ';');
    if (separatorOffset == -1) {
        // couldn't find ';', means we don't have extra params here.
        _value = [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];

        if (nil == _value) {
            VVHTTPLogError(@"MultipartFormDataParser: Bad MIME header value for header name: '%@'", _name);
            // tear down
            return nil;
        }
        return self;
    }

    _value = [[NSString alloc] initWithBytes:bytes length:separatorOffset encoding:encoding];
    VVHTTPLogVerbose(@"MultipartFormDataParser: Processing  header field '%@' : '%@'", _name, _value);
    // skipe the separator and the next ' ' symbol
    bytes += separatorOffset + 2;
    length -= separatorOffset + 2;

    // parse the "params" part of the header
    if (![self parseFormBytes:bytes length:length encoding:encoding]) {
        NSString *paramsStr = [[NSString alloc] initWithBytes:bytes length:length encoding:NSASCIIStringEncoding];
        VVHTTPLogError(@"MultipartFormDataParser: Bad params for header with name '%@' and value '%@'", _name, _value);
        VVHTTPLogError(@"MultipartFormDataParser: Params str: %@", paramsStr);

        return nil;
    }
    return self;
}

- (BOOL)parseFormBytes:(char *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    int offset = 0;
    NSString *currentParam = nil;
    BOOL insideQuote = NO;
    while (offset < length) {
        if (bytes[offset] == '\"') {
            if (!offset || bytes[offset - 1] != '\\') {
                insideQuote = !insideQuote;
            }
        }

        // skip quoted symbols
        if (insideQuote) {
            ++offset;
            continue;
        }
        if (bytes[offset] == '=') {
            if (currentParam) {
                // found '=' before terminating previous param.
                return NO;
            }
            currentParam = [[NSString alloc] initWithBytes:bytes length:offset encoding:NSASCIIStringEncoding];

            bytes += offset + 1;
            length -= offset + 1;
            offset = 0;
            continue;
        }
        if (bytes[offset] == '\"') {
            if (!currentParam) {
                // found ; before stating '='.
                VVHTTPLogError(@"MultipartFormDataParser: Unexpected ';' when parsing header");
                return NO;
            }

            NSString *paramValue = extractFormValue(bytes, offset, encoding);
            if (nil == paramValue) {
                VVHTTPLogWarn(@"MultipartFormDataParser: Failed to exctract paramValue for key %@ in header %@", currentParam, _name);
                return NO;
            } else {
                _params[currentParam] = paramValue;
                VVHTTPLogVerbose(@"MultipartFormDataParser: header param: %@ = %@", currentParam, paramValue);
            }

            currentParam = nil;

            // ';' separator has ' ' following, skip them.
            bytes += offset + 2;
            length -= offset + 2;
            offset = 0;
        }
        ++offset;
    }

    return YES;
}

- (BOOL)parseHeaderValueBytes:(char *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    int offset = 0;
    NSString *currentParam = nil;
    BOOL insideQuote = NO;
    while (offset < length) {
        if (bytes[offset] == '\"') {
            if (!offset || bytes[offset - 1] != '\\') {
                insideQuote = !insideQuote;
            }
        }

        // skip quoted symbols
        if (insideQuote) {
            ++offset;
            continue;
        }
        if (bytes[offset] == '=') {
            if (currentParam) {
                // found '=' before terminating previous param.
                return NO;
            }
            currentParam = [[NSString alloc] initWithBytes:bytes length:offset encoding:NSASCIIStringEncoding];

            bytes += offset + 1;
            length -= offset + 1;
            offset = 0;
            continue;
        }
        if (bytes[offset] == ';') {
            if (!currentParam) {
                // found ; before stating '='.
                VVHTTPLogError(@"MultipartFormDataParser: Unexpected ';' when parsing header");
                return NO;
            }
            NSString *paramValue = extractParamValue(bytes, offset, encoding);
            if (nil == paramValue) {
                VVHTTPLogWarn(@"MultipartFormDataParser: Failed to exctract paramValue for key %@ in header %@", currentParam, _name);
            } else {
#ifdef DEBUG
                if (_params[currentParam]) {
                    VVHTTPLogWarn(@"MultipartFormDataParser: param %@ mentioned more then once in header %@", currentParam, _name);
                }
#endif
                _params[currentParam] = paramValue;
                VVHTTPLogVerbose(@"MultipartFormDataParser: header param: %@ = %@", currentParam, paramValue);
            }

            currentParam = nil;

            // ';' separator has ' ' following, skip them.
            bytes += offset + 2;
            length -= offset + 2;
            offset = 0;
        }
        ++offset;
    }

    // add last param
    if (insideQuote) {
        VVHTTPLogWarn(@"MultipartFormDataParser: unterminated quote in header %@", _name);
//		return YES;
    }
    if (currentParam) {
        NSString *paramValue = extractParamValue(bytes, length, encoding);

        if (nil == paramValue) {
            VVHTTPLogError(@"MultipartFormDataParser: Failed to exctract paramValue for key %@ in header %@", currentParam, _name);
        }

#ifdef DEBUG
        if (_params[currentParam]) {
            VVHTTPLogWarn(@"MultipartFormDataParser: param %@ mentioned more then once in one header", currentParam);
        }
#endif
        _params[currentParam] = paramValue;
        VVHTTPLogVerbose(@"MultipartFormDataParser: header param: %@ = %@", currentParam, paramValue);
        currentParam = nil;
    }

    return YES;
}

- (void)extractFileType:(char *)bytes length:(NSUInteger)length {
    uint16_t separatorBytes = 0x0A0D;

    NSUInteger offset = 0, begin = 0;
    BOOL find = NO;
    while (offset < length) {
        if (bytes[offset] == ':') {
            find = YES;
            begin = offset + 2;
        }

        if (find && (*((uint16_t *) (bytes + offset)) == separatorBytes) && (*((uint16_t *) (bytes + offset) + 1) == separatorBytes)) {
            _contentType = [[NSString alloc] initWithBytes:bytes + begin length:offset - begin encoding:NSASCIIStringEncoding];
        }

        offset++;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@\n params: %@", _name, _value, _params];
}

@end

int findChar(const char *str, NSUInteger length, char c) {
    int offset = 0;
    while (offset < length) {
        if (str[offset] == c)
            return offset;
        ++offset;
    }
    return -1;
}

NSString *extractParamValue(const char *bytes, NSUInteger length, NSStringEncoding encoding) {
    if (!length)
        return nil;

    NSMutableString *value = nil;
    if (bytes[0] == '"') {
        // values may be quoted. Strip the quotes to get what we need.
        value = [[NSMutableString alloc] initWithBytes:bytes + 1 length:length - 2 encoding:encoding];
    } else {
        value = [[NSMutableString alloc] initWithBytes:bytes length:length encoding:encoding];
    }

    // restore escaped symbols
    NSRange range = [value rangeOfString:@"\\"];
    while (range.length) {
        [value deleteCharactersInRange:range];
        range.location++;
        range = [value rangeOfString:@"\\" options:NSLiteralSearch range:range];
    }

    return value;
}

NSString *extractFormValue(const char *bytes, NSUInteger length, NSStringEncoding encoding) {
    if (!length)
        return nil;

    NSMutableString *value = nil;
    if (bytes[0] == '"') {
        // values may be quoted. Strip the quotes to get what we need.
        value = [[NSMutableString alloc] initWithBytes:bytes + 1 length:length - 1 encoding:encoding];
    } else {
        value = [[NSMutableString alloc] initWithBytes:bytes length:length encoding:encoding];
    }

    // restore escaped symbols
    NSRange range = [value rangeOfString:@"\\"];
    while (range.length) {
        [value deleteCharactersInRange:range];
        range.location++;
        range = [value rangeOfString:@"\\" options:NSLiteralSearch range:range];
    }

    return value;
}

