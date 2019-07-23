#import <Foundation/Foundation.h>
#import "VVHTTPResponse.h"

@class VVHTTPConnection;


@interface VVHTTPFileResponse : NSObject <VVHTTPResponse> {
    VVHTTPConnection *connection;

    NSString *filePath;
    UInt64 fileLength;
    UInt64 fileOffset;

    BOOL aborted;

    int fileFD;
    void *buffer;
    NSUInteger bufferSize;
}

- (id)initWithFilePath:(NSString *)filePath forConnection:(VVHTTPConnection *)connection;

- (NSString *)filePath;

@end
