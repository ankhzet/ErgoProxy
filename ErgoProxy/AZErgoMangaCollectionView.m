//
//  AZErgoMangaCollectionView.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaCollectionView.h"
#import "AZErgoMangaViewItem.h"

@implementation AZErgoMangaCollectionView

- (NSCollectionViewItem *) newItemForRepresentedObject:(id)object {
	AZErgoMangaViewItem *item = [AZErgoMangaViewItem new];

	item.representedObject = object;

	return item;
}

@end
