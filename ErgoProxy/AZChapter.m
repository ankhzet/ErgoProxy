//
//  AZChapter.m
//  ErgoProxy
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZChapter.h"

#define __c(v1, v2, v3) ({__typeof__(v1) vd = v1 - v2; v3 = (vd != 0) ? vd / ABS(vd) : 0; })
NSComparator AZChapter_pageOrderComparator = ^NSComparisonResult(id obj1, id obj2) {
	AZPageChapterIndex i1 = [AZChapter decodeIndex:obj1 hasPageIDX:AZPageChapIDXDepthTillPage];
	AZPageChapterIndex i2 = [AZChapter decodeIndex:obj2 hasPageIDX:AZPageChapIDXDepthTillPage];

	NSComparisonResult c1;

	__c(i1.chapter, i2.chapter, c1);
	if (c1 == NSOrderedSame)
		__c(i1.page, i2.page, c1);

	return c1;
};

@implementation AZChapter

@end

@implementation AZChapter (Sorting)

/*!
 name_{#pageidx}.ext
 name_{#chaptidx}_{#pageidx}.ext
 name_{#chaptidx}_p{#pageidx}.ext
 name_{#chaptidx}_page{#pageidx}.ext
 name_c{#chaptidx}_{#pageidx}.ext
 name_ch{#chaptidx}_{#pageidx}.ext
 name_chap{#chaptidx}_{#pageidx}.ext

 name_{#volidx}_{#chaptidx}_{#pageidx}.ext
 */

#define C_SPEC_VOL '@'
#define C_SPEC_CHA '%'
#define C_SPEC_PAG '#'
#define C_SPEC_ALL @"@#%"

#define C_REPL_VOL @"@$1"
#define C_REPL_CHA @"%$1"
#define C_REPL_PAG @"#$1"

+ (AZPageChapterIndex) decodeIndex:(NSString *)sample hasPageIDX:(AZPageChapIDXDepth)hasPage {
	AZPageChapterIndex result = {.volume = 0, .chapter = 0.f, .page = 0, .straight = AZPageChapIDXDepthTillNone};

	NSMutableString *t = [[sample stringByReplacingOccurrencesOfString:@" " withString:@"_"] mutableCopy];

	NSRegularExpression *
	e11 = [NSRegularExpression regularExpressionWithPattern:@"[\\-_](?:c(?:h(?:apt?)?)?)[\\-_]?(\\d)"
																									options:NSRegularExpressionCaseInsensitive
																										error:nil];
	NSRegularExpression *
	e12 = [NSRegularExpression regularExpressionWithPattern:@"[\\-_](?:v(?:ol(?:ume)?)?)[\\-_]?(\\d)"
																									options:NSRegularExpressionCaseInsensitive
																										error:nil];
	NSRegularExpression *
	e13 = [NSRegularExpression regularExpressionWithPattern:@"[\\-_](?:p(?:age)?)[\\-_]?(\\d)"
																									options:NSRegularExpressionCaseInsensitive
																										error:nil];

	NSRegularExpression *
	e1 = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"[^\\d\\-\\.%@]", C_SPEC_ALL]
																								 options:NSRegularExpressionCaseInsensitive
																									 error:nil];
	NSRegularExpression *
	e14 = [NSRegularExpression regularExpressionWithPattern:@"(\\d)(?:-\\d+(?:\\.\\d+)?)"
																									options:NSRegularExpressionCaseInsensitive
																										error:nil];
	NSRegularExpression *
	e2 = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"[%@]", C_SPEC_ALL]
																								 options:NSRegularExpressionCaseInsensitive
																									 error:nil];

	[e2 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:@""];

	[e11 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:C_REPL_CHA];
	[e12 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:C_REPL_VOL];
	[e13 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:C_REPL_PAG];

	[e1 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:@" "];
	[e14 replaceMatchesInString:t options:0 range:NSMakeRange(0, [t length]) withTemplate:@"$1"];

	NSRegularExpression *
	e3 = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"([%@]?(\\d+)(\\.(\\d+))?)(?:-(?:\\d+)(?:\\.(?:\\d+))?)?", C_SPEC_ALL]
																								 options:0
																									 error:nil];

	NSArray *integers = [e3 matchesInString:t options:0 range:NSMakeRange(0, [t length])];

	AZPageChapIDXDepth has = hasPage >> 1;
	
	for (NSTextCheckingResult *r in [integers reverseObjectEnumerator]) {
		NSString *s = [t substringWithRange:r.range];
		switch ([s characterAtIndex:0]) {
			case C_SPEC_VOL: {
				result.volume = [[s substringFromIndex:1] intValue];
				result.straight |= AZPageChapIDXDepthTillVolume;
				has = MAX(has, AZPageChapIDXDepthTillVolume);
				break;
			}
			case C_SPEC_CHA: {
				result.chapter = [[s substringFromIndex:1] floatValue];
				result.straight |= AZPageChapIDXDepthTillChapter;
				has = MAX(has, AZPageChapIDXDepthTillChapter);
				break;
			}
			case C_SPEC_PAG: {
				result.page = [[s substringFromIndex:1] intValue];
				result.straight |= AZPageChapIDXDepthTillPage;
				has = MAX(has, AZPageChapIDXDepthTillPage);
				break;
			}

			default:
				switch (has) {
					case AZPageChapIDXDepthTillNone:
						result.page = [s intValue];
						has = AZPageChapIDXDepthTillPage;
						break;

					case AZPageChapIDXDepthTillPage:
						result.chapter = [s floatValue];
						has = AZPageChapIDXDepthTillChapter;
						break;

					case AZPageChapIDXDepthTillChapter:
						result.volume = [s intValue];
						has = AZPageChapIDXDepthTillVolume;
						break;

					case AZPageChapIDXDepthTillVolume:
					default:
						return result;
				}
				break;
		}
	}

	return result;
}

+ (float) decodeLast:(NSString *)sample numbers:(NSArray *)numbers {
	NSString *last = [numbers lastObject];
	if (!last)
		return 0.f;

	NSRange r = [last rangeOfString:@"-"];
	if (r.length && (r.location > 0))
		last = [last substringToIndex:r.location];

	return [last floatValue];
}

+ (float) decodeNth:(NSUInteger)n in:(NSString *)sample numbers:(NSArray *)numbers {
	NSUInteger c = [numbers count];
	NSString *last = (c >= n) ? numbers[c - n] : nil;
	if (!last)
		return 0.f;

	return [last floatValue];
}


+ (NSArray *) sort:(NSArray *)array {
	return [self sort:array with:AZChapter_pageOrderComparator];
}

+ (NSArray *) sort:(NSArray *)array with:(NSComparator)sorter {
	return [array sortedArrayUsingComparator:sorter];
}


@end
