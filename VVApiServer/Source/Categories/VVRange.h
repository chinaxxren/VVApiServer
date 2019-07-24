/**
 * DDRange is the functional equivalent of a 64 bit NSRange.
 * The HTTP Server is designed to support very large files.
 * On 32 bit architectures (ppc, i386) NSRange uses unsigned 32 bit integers.
 * This only supports a range of up to 4 gigabytes.
 * By defining our own variant, we can support a range up to 16 exabytes.
 *
 * All effort is given such that DDRange functions EXACTLY the same as NSRange.
**/

#import <Foundation/NSValue.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;

typedef struct _VVRange {
    UInt64 location;
    UInt64 length;
} VVRange;

typedef VVRange *VVRangePointer;

NS_INLINE VVRange DDMakeRange(UInt64 loc, UInt64 len) {
    VVRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE UInt64 VVMaxRange(VVRange range) {
    return (range.location + range.length);
}

NS_INLINE BOOL VVLocationInRange(UInt64 loc, VVRange range) {
    return (loc - range.location < range.length);
}

NS_INLINE BOOL VVEqualRanges(VVRange range1, VVRange range2) {
    return ((range1.location == range2.location) && (range1.length == range2.length));
}

FOUNDATION_EXPORT VVRange VVUnionRange(VVRange range1, VVRange range2);

FOUNDATION_EXPORT VVRange VVIntersectionRange(VVRange range1, VVRange range2);

FOUNDATION_EXPORT NSString *VVStringFromRange(VVRange range);

FOUNDATION_EXPORT VVRange VVRangeFromString(NSString *aString);

NSInteger DDRangeCompare(VVRangePointer pDDRange1, VVRangePointer pDDRange2);

@interface NSValue (NSValueVVRangeExtensions)

+ (NSValue *)valueWithVVRange:(VVRange)range;

- (VVRange)vvrangeValue;

- (NSInteger)vvrangeCompare:(NSValue *)other;

@end
