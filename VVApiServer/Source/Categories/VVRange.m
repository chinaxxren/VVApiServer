#import "VVRange.h"
#import "NSNumber+VVNumber.h"

VVRange VVUnionRange(VVRange range1, VVRange range2) {
    VVRange result;

    result.location = MIN(range1.location, range2.location);
    result.length = MAX(VVMaxRange(range1), VVMaxRange(range2)) - result.location;

    return result;
}

VVRange VVIntersectionRange(VVRange range1, VVRange range2) {
    VVRange result;

    if ((VVMaxRange(range1) < range2.location) || (VVMaxRange(range2) < range1.location)) {
        return DDMakeRange(0, 0);
    }

    result.location = MAX(range1.location, range2.location);
    result.length = MIN(VVMaxRange(range1), VVMaxRange(range2)) - result.location;

    return result;
}

NSString *VVStringFromRange(VVRange range) {
    return [NSString stringWithFormat:@"{%qu, %qu}", range.location, range.length];
}

VVRange VVRangeFromString(NSString *aString) {
    VVRange result = DDMakeRange(0, 0);

    // NSRange will ignore '-' characters, but not '+' characters
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];

    NSScanner *scanner = [NSScanner scannerWithString:aString];
    [scanner setCharactersToBeSkipped:[cset invertedSet]];

    NSString *str1 = nil;
    NSString *str2 = nil;

    BOOL found1 = [scanner scanCharactersFromSet:cset intoString:&str1];
    BOOL found2 = [scanner scanCharactersFromSet:cset intoString:&str2];

    if (found1) [NSNumber parseString:str1 intoUInt64:&result.location];
    if (found2) [NSNumber parseString:str2 intoUInt64:&result.length];

    return result;
}

NSInteger DDRangeCompare(VVRangePointer pDDRange1, VVRangePointer pDDRange2) {
    // Comparison basis:
    // Which range would you encouter first if you started at zero, and began walking towards infinity.
    // If you encouter both ranges at the same time, which range would end first.

    if (pDDRange1->location < pDDRange2->location) {
        return NSOrderedAscending;
    }
    if (pDDRange1->location > pDDRange2->location) {
        return NSOrderedDescending;
    }
    if (pDDRange1->length < pDDRange2->length) {
        return NSOrderedAscending;
    }
    if (pDDRange1->length > pDDRange2->length) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

@implementation NSValue (NSValueVVRangeExtensions)

+ (NSValue *)valueWithVVRange:(VVRange)range {
    return [NSValue valueWithBytes:&range objCType:@encode(VVRange)];
}

- (VVRange)vvrangeValue {
    VVRange result;
    [self getValue:&result];
    return result;
}

- (NSInteger)vvrangeCompare:(NSValue *)other {
    VVRange r1 = [self vvrangeValue];
    VVRange r2 = [other vvrangeValue];

    return DDRangeCompare(&r1, &r2);
}

@end
