//
//  AZErgoMangachanSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoMangachanSource.h"
#import "AZHTMLRequest.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"

#import "AZErgoCountingConflictsSolver.h"

@implementation AZErgoMangachanSource

+ (NSString *) serverURL {
	return @"mangachan.ru";
}

- (id) action:(NSString *)action request:(NSString *)genData {
	AZHTMLRequest *request = [super action:action request:genData];

	request.url = [NSString stringWithFormat:@"%@/%@/%@.html", request.url, action, genData];
	return request;
}

+ (NSRegularExpression *)idxFilterRegEx {
	static NSRegularExpression *r;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    r = [NSRegularExpression regularExpressionWithPattern:@"^(.*)\u00a0v([\\d\\.]+) - ([\\d\\.]+)(.*)"
																									options:NSRegularExpressionCaseInsensitive
																										error:nil];
	});
	return r;
}

+ (NSString *) chapter:(NSString *)pattern element:(NSUInteger)element {
	NSRegularExpression *regex = [self idxFilterRegEx];

	NSTextCheckingResult *match = [regex firstMatchInString:pattern options:0 range:NSMakeRange(0, [pattern length])];

	if (match) {
		pattern = [pattern substringWithRange:[match rangeAtIndex:element]];
		return pattern;
	}

	return nil;
}

- (NSArray *) chaptersFromDocument:(TFHpple *)document {
	NSMutableArray *result = [NSMutableArray array];

	NSArray *chapterRows = [document searchWithXPathQuery:@"//table[contains(@class,'table_cha')]//a[contains(@href,'/online/')]//ancestor::tr"];

	NSRegularExpression *hrefFilter = [NSRegularExpression regularExpressionWithPattern:@"([^/]+)\\.html" options:NSRegularExpressionCaseInsensitive error:nil];

	NSDateFormatter *df = [NSDateFormatter new];
	[df setDateFormat:@"yyyy-MM-dd"];

	NSMutableDictionary *chapters = [NSMutableDictionary dictionaryWithCapacity:[chapterRows count]];

	for (TFHppleElement *row in chapterRows) {
		TFHppleElement *link = [[row searchWithXPathQuery:@"//a[contains(@href,'/online/')]"] firstObject];
		TFHppleElement *date = [[row searchWithXPathQuery:@"//*[contains(@class,'date')]"] firstObject];

		NSString *href = [link objectForKey:@"href"];
		NSTextCheckingResult *match = [hrefFilter firstMatchInString:href
																												 options:0
																													 range:NSMakeRange(0, [href length])];

		if (match) {

			NSString *genData = [href substringWithRange:[match rangeAtIndex:1]];

			float idx = MAX(1, [[self class] chapterIdx:[link text]]);
			int volume = [[self class] chapterVolume:[link text]];

			NSString *title = [[self class] chapterTitle:[link text]];

			NSDate *submitDate = [df dateFromString:[date text]];

			__block BOOL created = NO;
			void (^initBlock)(AZErgoUpdateChapter *entity) = ^void(AZErgoUpdateChapter *entity) {
				entity.genData = genData;
				entity.title = [title length] ? title : [NSString stringWithFormat:@"v%d - %.1f", volume, idx];
				entity.idx = idx;
				entity.volume = volume;
				entity.date = submitDate;

				//				 NSLog(@"%@: %@ (%@)", [date text], [df stringFromDate:entity.date], entity.date);

				created = YES;
			};
			AZErgoUpdateChapter *chapter = [AZErgoUpdateChapter unique:[NSPredicate predicateWithFormat:@"genData == %@", genData]
																												initWith:initBlock];

			if (!created) {
				//				[chapter delete];
				//				chapter = [AZErgoUpdateChapter unique:[NSPredicate predicateWithFormat:@"genData like %@", genData]
				//																													initWith:initBlock];

			}

			initBlock(chapter);

			if (chapter.watch)
				chapter.watch.title = [[self class] chapterTip:[link text]];
			else
				chapter.mangaName = [[self class] chapterTip:[link text]];

			chapters[genData] = chapter;

			//			 [chapter delete];
			[result addObject:chapter];
		}
	}

	[[AZErgoCountingConflictsSolver solverForChapters:[chapters allValues]] solveConflicts];

	return result;
}

- (NSArray *) scansFromDocument:(TFHpple *)document {
	TFHppleElement *script = [[document searchWithXPathQuery:@"//script[contains(text(),'function update_page')]"] firstObject];
	if (!script)
		return nil;

	NSString *text = [[script firstChild] content];
	if (!text)
		return nil;

	NSString *pattern = @"\"fullimg\"\\s*:\\s*\\[\\s*\"([^\\]]+)\\s*\",\\s*\\]";
	NSRegularExpression *scans = [NSRegularExpression regularExpressionWithPattern:pattern
																																				 options:NSRegularExpressionCaseInsensitive
																																					 error:nil];

	NSTextCheckingResult *match = [scans firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
	if (!match)
		return nil;


	text = [text substringWithRange:[match rangeAtIndex:1]];
	NSArray *result = [text componentsSeparatedByString:@"\",\""];
	
	return result;
}

@end
