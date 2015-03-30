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
#import "AZErgoChapterProtocol.h"

#import "AZDataProxy.h"

@implementation AZErgoMangachanSource

+ (NSString *) serverURL {
	return @"mangachan.ru";
}

- (BOOL) correspondsTo:(NSString *)resoureURL {
	return [resoureURL rangeOfString:[[self class] serverURL] options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSString *) parseURL:(NSString *)url {
	NSRange p1 = [url rangeOfString:[[self class] serverURL] options:NSCaseInsensitiveSearch];

	if (!!p1.length)
		url = [url substringFromIndex:p1.location + p1.length];

	if ([url hasPrefix:@"/manga/"] || [url hasPrefix:@"/online/"]) {
		url = [url substringFromIndex:[url lastOccurance:@"/"].location + 1];
		url = [url stringByReplacingOccurrencesOfString:@".html" withString:@"" options:NSCaseInsensitiveSearch range:[url stringRange]];
		return url;
	}

	return url;
}

- (NSString *) genDataToFolder:(NSString *)genData {
	NSRange r = [genData rangeOfString:@"-"];
	if (r.length)
		genData = [genData substringFromIndex:r.location + r.length];

	return genData;
}

- (id) action:(NSString *)action request:(NSString *)genData {
	AZHTMLRequest *request = [super action:action request:genData];

	if ([action isCaseInsensitiveLike:@"search"]) {
		[request setParameters:@{@"do": @"search",
														 @"subaction": @"search",
														 @"result_num": @"100",
														 @"story": genData}];

		request.httpMethod = HTTP_POST;
	} else
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

	for (TFHppleElement *row in chapterRows) {
		TFHppleElement *link = [[row searchWithXPathQuery:@"//a[contains(@href,'/online/')]"] firstObject];
		TFHppleElement *date = [[row searchWithXPathQuery:@"//*[contains(@class,'date')]"] firstObject];

		NSString *href = [link objectForKey:@"href"];
		NSTextCheckingResult *match = [hrefFilter firstMatchInString:href
																												 options:0
																													 range:NSMakeRange(0, [href length])];

		if (match) {

			NSString *genData = [href substringWithRange:[match rangeAtIndex:1]];

			float idx = MAX(0.1, [[self class] chapterIdx:[link text]]);
			int volume = [[self class] chapterVolume:[link text]];

			NSString *title = [[self class] chapterTitle:[link text]];

			NSDate *submitDate = [df dateFromString:[date text]];

			Chapter *data = [Chapter chapter:idx ofVolume:volume];
			data.genData = genData;
			data.title = [title length] ? title : [NSString stringWithFormat:@"v%d - %.1f", volume, idx];
			data.date = submitDate;
			data.mangaName = [[self class] chapterTip:[link text]];

			[result addObject:data];

		}
	}

	[[AZErgoCountingConflictsSolver solverForChapters:result] solveConflicts];

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

- (NSArray *) titlesFromDocument:(TFHpple *)document {
	TFHppleElement *titleElement = [[document searchWithXPathQuery:@"//div[contains(@id,'info_wrap')]//div[contains(@class,'name_row')]//a"] firstObject];

	if (!titleElement)
		return @[];

	NSString *titleCommon = [titleElement text];

	NSMutableSet *titles = [[self parseTitles:titleCommon] mutableCopy];

	TFHppleElement *additionalTitlesElement = [[document searchWithXPathQuery:@"//table[contains(@class,'mangatitle')]//tr[1]//h2"] firstObject];

	NSString *additional = [additionalTitlesElement text];

	for (NSString *title in [additional componentsSeparatedByString:@";"])
		[titles addObject:[self cleanupEntityStr:title]];

	return [titles allObjects];
}

- (NSString *) annotationFromDocument:(TFHpple *)document {
	TFHppleElement *annotationElement = [[document searchWithXPathQuery:@"//div[contains(@id,'description')]"] firstObject];

	return [self cleanupEntityStr:[annotationElement text]];
}

- (NSArray *) tagsFromDocument:(TFHpple *)document {
	NSArray *tagElements = [document searchWithXPathQuery:@"//table[contains(@class,'mangatitle')]//tr[6]//a"];
	AZ_Mutable(Set, *tags);

	for (TFHppleElement *tagA in tagElements)
		[tags addObject:[self mappedTagName:[self cleanupEntityStr:[tagA text]]]];

	return [tags allObjects];
}

- (NSString *) cleanupEntityStr:(NSString *)string {
	NSCharacterSet *filter = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [string stringByTrimmingCharactersInSet:filter];
}

- (NSString *) previewFromDocument:(TFHpple *)document {
	TFHppleElement *previewElement = [[document searchWithXPathQuery:@"//div[contains(@id,'manga_images')]/a/img[contains(@id,'cover')]"] firstObject];

	return [previewElement objectForKey:@"src"];
}

- (NSString *) mappedTagName:(NSString *)name {

	NSDictionary *map =
	@{
		@"18_плюс": @"18+",
		@"арт": @"art",
		@"боевик": @"boevik",
		@"боевые_искусства": @"fightskill",
		@"вампиры": @"vampire",
		@"веб": @"webtoon",
		@"гарем": @"harem",
		@"гендерная_интрига": @"gender-bender",
		@"героическое_фэнтези": @"heroic fantasy",
		@"детектив": @"detective",
		@"дзёсэй": @"dsesey",
		@"додзинси": @"dodjinshi",
		@"драма": @"drama",
		@"игра": @"game",
		@"инцест": @"incest",
		@"искусство": @"arts",
		@"история": @"historical",
		@"киберпанк": @"cyberpunk",
		@"кодомо": @"codomo",
		@"комедия": @"comedy",
		@"литРПГ": @"LitRPG",
		@"махо-сёдзё": @"maho-shoudjo",
		@"меха": @"mecha",
		@"мистика": @"mystery",
		@"музыка": @"music",
		@"научная_фантастика": @"sci-fi",
		@"повседневность": @"routine",
		@"постапокалиптика": @"postapocaliptic",
		@"приключения": @"adventure",
		@"психология": @"psycho",
		@"романтика": @"romance",
		@"самурайский_боевик": @"samurai",
		@"сборник": @"collection",
		@"сверхъестественное": @"supernatural",
		@"спорт": @"sport",
		@"сэйнэн": @"seinen",
		@"сёдзё": @"shoujo",
		@"сёдзё-ай": @"shoujo-ai",
		@"сёнэн": @"shounen",
		@"сёнэн-ай": @"shounen-ai",
		@"тентакли": @"tentacles",
		@"трагедия": @"tragedy",
		@"триллер": @"thriller",
		@"ужасы": @"horror",
		@"фантастика": @"fantastic",
		@"фэнтези": @"fantasy",
		@"школа": @"school",
		@"эротика": @"erotic",
		@"юри": @"yuri",
		@"яой": @"yaoi",
		@"ёнкома": @"enkoma",
		};

	return map[name] ?: name;
}

- (NSSet *) parseTitles:(NSString *)string {
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	NSString *pattern = @"^(.*?)(/((.*?)/))?$";

	if ([string isLike:@"*(*)*(*)"])
		pattern = @"^(.*?)(/(([^/(/)]*?)/))$";

	if ([string isLike:@"*(*)*(*(*)*)"]) {
		NSString *z = @".*?";
		pattern = [NSString stringWithFormat:@"^%@$",
								[NSString stringWithFormat:@"(%@/(%@/)%@)(/(%@/))", z, z, z,
									[NSString stringWithFormat:@"(%@/(%@/)%@)", z, z, z]
								 ]
							 ];
	}


	NSArray *indicies = @[@1, @3];
	NSDictionary *match = [string allMatches:[pattern stringByReplacingOccurrencesOfString:@"/" withString:@"\\"]
															 withIndices:indicies];


	AZ_Mutable(Set, *titles);

	NSString *r;
	for (id index in indicies)
		if ([(r = [self cleanupEntityStr:match[index]]) length] > 0)
			[titles addObject:r];

	return titles;
}

- (NSDictionary *) entitiesFromDocument:(TFHpple *)document {
	NSString *q = @"//div[contains(@id,'dle-content')]/div[contains(@class,'content_row')]/div[contains(@class,'manga_row1')]/div/h2/a";

	NSArray *eElements = [document searchWithXPathQuery:q];
	AZ_Mutable(Dictionary, *entities);

	for (TFHppleElement *element in eElements) {
		NSString *href = [element objectForKey:@"href"];
		href = [self parseURL:href];
		entities[href] = [element text];
	}

	return entities;
}

- (BOOL) isCompleteFromDocument:(TFHpple *)document {
	TFHppleElement *complete = [document peekAtSearchWithXPathQuery:@"//table[contains(@class,'')]//td/h2/font[contains(text(), 'перевод завершен')]"];

	return (!!complete);
}


@end

