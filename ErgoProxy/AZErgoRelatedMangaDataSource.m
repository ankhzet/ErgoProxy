//
//  AZErgoRelatedMangaDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 20.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoRelatedMangaDataSource.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoRelatedMangaDataSource

- (NSString *) rootIdentifierFromItem:(id)item {
	return [self rootNodeOf:item];
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return [self groupNodeOf:item];
}

- (id) rootNodeOf:(AZErgoManga *)manga {
	return @(manga.isComplete ? AZErgoTagGroupComplete : 0);
}

- (id) groupNodeOf:(AZErgoManga *)manga {
	return @(manga.isDownloaded ? AZErgoTagGroupDownloaded : 0);
}

- (id<NSCopying>) orderedUID:(AZErgoManga *)manga {
	return manga.mainTitle ?: @"<o_O>";
}

@end
