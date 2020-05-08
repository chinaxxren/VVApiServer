#import "VVApiConnection.h"

#import "VVApiHTTPServer.h"
#import "VVHTTPMessage.h"
#import "VVHTTPConfig.h"
#import "VVApiJSON.h"
#import "MultipartMessageHeader.h"
#import "MultipartMessageHeaderField.h"
#import "VVHTTPLogging.h"
#import "MultipartFormDataParser.h"
#import "VVFileParams.h"

static const int httpLogLevel = VV_HTTP_LOG_LEVEL_VERBOSE | VV_HTTP_LOG_FLAG_TRACE;

@implementation VVApiConnection {
    __weak VVApiHTTPServer *_httpServer;
    NSDictionary *_headerDict;

    MultipartFormDataParser *_parser;
    NSFileHandle *_storeFile;
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
        NSAssert([config.server isKindOfClass:[VVApiHTTPServer class]],
                @"A VVApiConnection is being used with a server that is not a VVApiHTTPServer");

        _httpServer = (VVApiHTTPServer *) config.server;
    }
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    if ([_httpServer supportsMethod:method])
        return YES;

    return [super supportsMethod:method atPath:path];
}

- (void)processBodyData:(NSData *)postDataChunk {
    if ([_requestMessage headerField:@"boundary"]) {
        // append data to the parser. It will invoke callbacks to let us handle
        // parsed data.
        [_parser appendData:postDataChunk];
    } else {
        BOOL result = [_requestMessage appendData:postDataChunk];
        if (!result) {

        }
    }
}

- (void)prepareForBodyWithSize:(UInt64)contentLength {

    // set up mime parser
    NSString *boundary = [_requestMessage headerField:@"boundary"];
    _parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    _parser._delegate = self;
}

- (NSObject <VVHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    NSURL *url = [_requestMessage url];
    NSDictionary *headers = [_requestMessage allHeaderFields];

    NSString *query = nil;
    _headerDict = nil;
    NSMutableDictionary *params = nil;

    if (url) {
        path = [url path]; // Strip the query string from the path

        if (_requestMessage.params) {
            params = _requestMessage.params;
        } else {
            NSData *data = [_requestMessage body];
            if (data.length > 0) {
                query = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            } else {
                query = [url query];
            }

            if (query) {
                params = [self parseParams:query];
            }
        }
        
        [params removeObjectForKey:VV_API_DELAY];
    }

    VVApiResponse *response = [_httpServer apiMethod:method
                                            withPath:path
                                             headers:headers
                                          parameters:params
                                               files:_requestMessage.files
                                             request:_requestMessage
                                          connection:self];
    if (response != nil) {
        _headerDict = response.headers;
        return response;
    }

    // Set a MIME type for static files if possible
    NSObject <VVHTTPResponse> *staticResponse = [super httpResponseForMethod:method URI:path];
    if (staticResponse && [staticResponse respondsToSelector:@selector(filePath)]) {
        NSString *mimeType = [_httpServer mimeTypeForPath:[staticResponse performSelector:@selector(filePath)]];
        if (mimeType) {
            _headerDict = @{@"Content-Type": mimeType};
        }
    }

    return staticResponse;
}

- (void)setHeadersForResponse:(VVHTTPMessage *)response isError:(BOOL)isError {
    [_httpServer.defaultHeaderDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
        [response setHeaderField:field value:value];
    }];

    if (_headerDict && !isError) {
        [_headerDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
            [response setHeaderField:field value:value];
        }];
    }

    // Set the connection header if not already specified
    NSString *connection = [response headerField:@"Connection"];
    if (!connection) {
        connection = [self shouldDie] ? @"close" : @"keep-alive";
        [response setHeaderField:@"Connection" value:connection];
    }
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path {
    if ([method isEqualToString:VV_API_POST]) {
        NSString *contentType = [_requestMessage headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if (NSNotFound == paramsSeparator) {
            return NO;
        }

        if (paramsSeparator >= contentType.length - 1) {
            return NO;
        }

        NSString *type = [contentType substringToIndex:paramsSeparator];
        if (![type isEqualToString:@"multipart/form-data"]) {
            // we expect multipart/form-data content type
            return NO;
        }

        // enumerate all params in content-type, and find boundary there
        NSArray *params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for (NSString *param in params) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if ((NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1) {
                continue;
            }
            NSString *paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator - 1)];
            NSString *paramValue = [param substringFromIndex:paramsSeparator + 1];

            if ([paramName isEqualToString:@"boundary"]) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [_requestMessage setHeaderField:@"boundary" value:paramValue];
            }
        }

        // check if boundary specified
        if (nil == [_requestMessage headerField:@"boundary"]) {
            return NO;
        }

        return YES;
    }

    return NO;
}

- (NSData *)preprocessResponse:(VVHTTPMessage *)response {
    [self setHeadersForResponse:response isError:NO];
    return [super preprocessResponse:response];
}

- (NSData *)preprocessErrorResponse:(VVHTTPMessage *)response {
    [self setHeadersForResponse:response isError:YES];
    return [super preprocessErrorResponse:response];
}

- (BOOL)shouldDie {
    __block BOOL shouldDie = [super shouldDie];

    // Allow custom headers to determine if the connection should be closed
    if (!shouldDie && _headerDict) {
        [_headerDict enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
            if ([field caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
                if ([value caseInsensitiveCompare:@"close"] == NSOrderedSame) {
                    shouldDie = YES;
                }
                *stop = YES;
            }
        }];
    }

    return shouldDie;
}

#pragma mark multipart form data parser delegate

- (void)processStartOfPartWithHeader:(MultipartMessageHeader *)header {
    // in this sample, we are not interested in parts, other then file parts.
    // check content disposition to find out filename

    MultipartMessageHeaderField *disposition = header.fields[@"Content-Disposition"];
    NSString *filename = [disposition.params[@"filename"] lastPathComponent];
    if ((nil == filename) || [filename isEqualToString:@""]) {
        // it's either not a file part, or
        // an empty form sent. we won't handle it.
        return;
    }

    NSString *uploadDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    BOOL isDir = YES;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if (![defaultManager fileExistsAtPath:uploadDirPath isDirectory:&isDir]) {
        [defaultManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *filePath = [uploadDirPath stringByAppendingPathComponent:filename];

    if ([defaultManager fileExistsAtPath:filePath]) {
        [defaultManager removeItemAtPath:filePath error:nil];
    } else {
        VVHTTPLogVerbose(@"Saving file to %@", filePath);
        if (![defaultManager createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil]) {
            VVHTTPLogError(@"Could not create directory at path: %@", filePath);
        }
        if (![defaultManager createFileAtPath:filePath contents:nil attributes:nil]) {
            VVHTTPLogError(@"Could not create file at path: %@", filePath);
        }
    }

    if (!_requestMessage.files) {
        _requestMessage.files = [[NSMutableArray alloc] init];
    }

    NSString *field = disposition.params[@"name"];
    if (field) {
        VVFileParams *fileParams = [[VVFileParams alloc] init];
        fileParams.field = field;
        fileParams.filename = filename;
        fileParams.path = filePath;
        fileParams.type = disposition.contentType;
        [_requestMessage.files addObject:fileParams];
    }

    _storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
}

- (void)processContent:(NSData *)data WithHeader:(MultipartMessageHeader *)header {
    // here we just write the output from parser to the file.
    if (header.file) {
        if (_storeFile) {
            [_storeFile writeData:data];
        }
    } else {
        if (!data) {
            return;
        }

        MultipartMessageHeaderField *headerField = header.fields[@"Content-Disposition"];
        if (!headerField) {
            return;
        }

        NSString *field = headerField.params[@"name"];
        if (!field) {
            return;
        }

        if (!_requestMessage.params) {
            _requestMessage.params = [[NSMutableDictionary alloc] init];
        }

        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        _requestMessage.params[field] = value;
    }
}

- (void)processEndOfPartWithHeader:(MultipartMessageHeader *)header {
    // as the file part is over, we close the file.
    if (_storeFile) {
        [_storeFile closeFile];
        _storeFile = nil;
    }
}

- (void)processPreambleData:(NSData *)data {
    // if we are interested in preamble data, we could process it here.
}

- (void)processEpilogueData:(NSData *)data {
    // if we are interested in epilogue data, we could process it here.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"processEpilogueData" object:nil];
}

@end
