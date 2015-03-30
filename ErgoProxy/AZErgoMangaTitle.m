//
//  AZErgoMangaTitle.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaTitle.h"
#import "AZErgoManga.h"


@implementation AZErgoMangaTitle

@dynamic title;
@dynamic manga;


+ (instancetype) mangaTitile:(NSString *)title {
	return [self unique:[NSPredicate predicateWithFormat:@"title ==[c] %@", title] initWith:^(AZErgoMangaTitle *entity) {
		entity.title = [title uppercaseFirstCharString];
	}];
}

@end
