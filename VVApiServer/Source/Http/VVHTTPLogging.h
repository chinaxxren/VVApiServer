
#import <Foundation/Foundation.h>

#define VV_HTTP_Logging(level, frmt, ...) [HTTPLogging vv_log:level format:frmt, ##__VA_ARGS__]

#define VV_THIS_FILE   self
#define VV_THIS_METHOD NSStringFromSelector(_cmd)

#define VV_HTTP_LOG_FLAG_ERROR   (1 << 0)
#define VV_HTTP_LOG_FLAG_WARN    (1 << 1)
#define VV_HTTP_LOG_FLAG_INFO    (1 << 2)
#define VV_HTTP_LOG_FLAG_VERBOSE (1 << 3)
#define VV_HTTP_LOG_FLAG_TRACE   (1 << 4)

#define VV_HTTP_LOG_LEVEL_OFF     0
#define VV_HTTP_LOG_LEVEL_ERROR   (VV_HTTP_LOG_LEVEL_OFF   | VV_HTTP_LOG_FLAG_ERROR)
#define VV_HTTP_LOG_LEVEL_WARN    (VV_HTTP_LOG_LEVEL_ERROR | VV_HTTP_LOG_FLAG_WARN)
#define VV_HTTP_LOG_LEVEL_INFO    (VV_HTTP_LOG_LEVEL_WARN  | VV_HTTP_LOG_FLAG_INFO)
#define VV_HTTP_LOG_LEVEL_VERBOSE (VV_HTTP_LOG_LEVEL_INFO  | VV_HTTP_LOG_FLAG_VERBOSE)

#define VV_HTTP_LOG_ERROR   (httpLogLevel & VV_HTTP_LOG_FLAG_ERROR)
#define VV_HTTP_LOG_WARN    (httpLogLevel & VV_HTTP_LOG_FLAG_WARN)
#define VV_HTTP_LOG_INFO    (httpLogLevel & VV_HTTP_LOG_FLAG_INFO)
#define VV_HTTP_LOG_VERBOSE (httpLogLevel & VV_HTTP_LOG_FLAG_VERBOSE)
#define VV_HTTP_LOG_TRACE   (httpLogLevel & VV_HTTP_LOG_FLAG_TRACE)

#define VVHTTPLogError(frmt, ...)    VV_HTTP_Logging(VV_HTTP_LOG_ERROR,   frmt, ##__VA_ARGS__)
#define VVHTTPLogWarn(frmt, ...)     VV_HTTP_Logging(VV_HTTP_LOG_WARN,    frmt, ##__VA_ARGS__)
#define VVHTTPLogInfo(frmt, ...)     VV_HTTP_Logging(VV_HTTP_LOG_INFO,    frmt, ##__VA_ARGS__)
#define VVHTTPLogVerbose(frmt, ...)  VV_HTTP_Logging(VV_HTTP_LOG_VERBOSE, frmt, ##__VA_ARGS__)
#define VVHTTPLogTrace()             VV_HTTP_Logging(VV_HTTP_LOG_TRACE,   @"%@ : %@", VV_THIS_FILE, VV_THIS_METHOD)
#define VVHTTPLogTrace2(frmt, ...)   VV_HTTP_Logging(VV_HTTP_LOG_TRACE,   frmt, ##__VA_ARGS__)


@interface VVHTTPLogging : NSObject

+ (void)vv_log:(int)level format:(NSString *)format, ...;

@end
