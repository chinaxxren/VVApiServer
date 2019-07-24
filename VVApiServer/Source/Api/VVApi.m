#import "VVApi.h"

@implementation VVApi

+ (VVApi *)apiWithPath:(NSString *)path {
    VVApi *api = [VVApi new];
    api.path = path;

    NSMutableArray *keys = [NSMutableArray array];
    if ([path length] > 2 && [path characterAtIndex:0] == '{') {
        // This is a custom regular expression, just remove the {}
        path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
    } else {
        NSRegularExpression *regex = nil;

        // Escape regex characters
        regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
        path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];

        // Parse any :parameters and * in the path
        regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)"
                                                          options:0
                                                            error:nil];
        __block NSInteger diff = 0;
        NSMutableString *regexPath = [NSMutableString stringWithString:path];
        [regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
                                 NSString *replacementString;

                                 NSString *capturedString = [path substringWithRange:result.range];
                                 if ([capturedString isEqualToString:@"*"]) {
                                     [keys addObject:@"wildcards"];
                                     replacementString = @"(.*?)";
                                 } else {
                                     NSString *keyString = [path substringWithRange:[result rangeAtIndex:2]];
                                     [keys addObject:keyString];
                                     replacementString = @"([^/]+)";
                                 }

                                 [regexPath replaceCharactersInRange:replacementRange withString:replacementString];
                                 diff += replacementString.length - result.range.length;
                             }];

        path = [NSString stringWithFormat:@"^%@$", regexPath];
    }

    api.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
    if ([keys count] > 0) {
        api.keys = keys;
    }

    return api;
}

@end
