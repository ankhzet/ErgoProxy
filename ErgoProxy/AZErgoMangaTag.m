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
	return [self filter:[NSPredicate predicateWithFormat:@"guid == %@", guid] limit:1];
}

+ (instancetype) tagByName:(NSString *)name {
	return [self filter:[NSPredicate predicateWithFormat:@"tag ==[c] %@", name] limit:1];
}

- (NSComparisonResult) caseInsensitiveCompare:(id) other {
	return [self.tag caseInsensitiveCompare:((AZErgoMangaTag *)other).tag];
}

@end
