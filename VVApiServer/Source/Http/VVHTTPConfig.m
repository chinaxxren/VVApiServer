//
// Created by Tank on 2019-07-25.
// Copyright (c) 2019 Tank. All rights reserved.
//

#import "VVHTTPConfig.h"


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation HTTPConfig

@synthesize server;
@synthesize documentRoot;
@synthesize queue;

- (id)initWithServer:(VVHTTPServer *)aServer documentRoot:(NSString *)aDocumentRoot {
    if ((self = [super init])) {
        server = aServer;
        documentRoot = aDocumentRoot;
    }

    return self;
}

- (id)initWithServer:(VVHTTPServer *)aServer documentRoot:(NSString *)aDocumentRoot queue:(dispatch_queue_t)q {
    if ((self = [super init])) {
        server = aServer;

        documentRoot = [aDocumentRoot stringByStandardizingPath];
        if ([documentRoot hasSuffix:@"/"]) {
            documentRoot = [documentRoot stringByAppendingString:@"/"];
        }

        if (q) {
            queue = q;
        }
    }

    return self;
}

@end