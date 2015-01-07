//
//  AZErgoManga.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoManga.h"
#import "AZErgoMangaProgress.h"
#import "AZErgoMangaTag.h"
#import "AZErgoMangaTitle.h"


@implementation AZErgoManga

@dynamic annotation;
@dynamic name;
@dynamic tags;
@dynamic titles;
@dynamic progress;

- (NSString *) mainTitle {
	NSArray *t = [self titleEntities:YES];
	if ([t count])
		return [t firstObject];

	return [[self titleEntities:NO] firstObject];
}

- (NSArray *) additionalTitles {
	NSArray *latin = [self titleEntities:NO];

	NSArray *cyr = [self titleEntities:YES];

	NSUInteger c = [cyr count];
	switch (c) {
		case 1:
			break;
		case 0:
			latin = [latin subarrayWithRange:NSMakeRange(1, [latin count] - 1)];
			break;
		default:
			latin = [cyr subarrayWithRange:NSMakeRange(1, c - 1)];
			break;
	}

	return latin;
}

- (NSArray *) titleEntities:(BOOL)cyrylic {
	NSMutableArray *titles = [NSMutableArray new];

	NSCharacterSet *filtered = [NSCharacterSet characterSetWithCharactersInString:@"йцукенгшщзхъёфывапролджэячсмитьбюїґєі"];
	for (AZErgoMangaTitle *title in [self.titles allObjects]) {
		BOOL isCyrylic = [title.title rangeOfCharacterFromSet:filtered].location != NSNotFound;
    if (isCyrylic ^ !cyrylic)
			[titles addObject:title.title];
	}

	return [titles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSArray *) tagNames {
	NSMutableArray *tags = [NSMutableArray new];
	for (AZErgoMangaTag *tag in [self.tags allObjects])
		[tags addObject:[tag.tag lowercaseString]];

	return tags;
}

- (AZErgoMangaTag *) toggle:(BOOL)on tag:(NSUInteger)guid {
	AZErgoMangaTag *tag = [AZErgoMangaTag tagByGuid:@(guid)];
	
	if (on)
		[tag addMangaObject:self];
	else
		[tag removeMangaObject:self];

	return tag;
}

@end
