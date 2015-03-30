//
//  AZErgoMangaTag.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaTag.h"
#import "AZErgoManga.h"


@implementation AZErgoMangaTag
@dynamic tag, annotation, manga, guid, skip;

+ (instancetype) tagByGuid:(NSNumber *)guid {
	return [self any:@"guid == %@", guid];
}

+ (instancetype) tagByName:(NSString *)name {
	return [self any:@"tag ==[c] %@", name];
}

+ (instancetype) tagWithGuid:(NSNumber *)guid {
	return [self unique:[NSPredicate predicateWithFormat:@"guid == %@", guid] initWith:^(AZErgoMangaTag *tag) {
		tag.guid = guid;
		tag.tag = [NSString stringWithFormat:@":%@", guid];
	}];
}

+ (instancetype) tagWithName:(NSString *)name {
	return [self unique:[NSPredicate predicateWithFormat:@"tag ==[c] %@", name] initWith:^(AZErgoMangaTag *tag) {
		tag.tag = name;
	}];
}

+ (NSArray *) taggedManga:(AZErgoTagGroup)guid {
	AZErgoMangaTag *tag = [self tagByGuid:@(guid)];
	return [tag.manga allObjects];
}

- (NSComparisonResult) caseInsensitiveCompare:(id) other {
	return [self.tag caseInsensitiveCompare:((AZErgoMangaTag *)other).tag];
}

+ (NSString *) tagGroupName:(AZErgoTagGroup)group {
	switch (group) {
		case AZErgoTagGroupComplete:
		case AZErgoTagGroupReaded:
		case AZErgoTagGroupDownloaded:
		case AZErgoTagGroupSuspended:
			return (@"Progress tags");

		case AZErgoTagGroupWebtoon:
			return (@"Type tags");

		case AZErgoTagGroupAdult:
			return (@"Rated content (18+)");

		default:
			return (@"Common tags");
	}
}

@end
