//
//  AZErgoMangaViewItem.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZErgoManga;

@protocol AZErgoMangaViewItemDelegate <NSObject>

- (void) viewItem:(id)sender showInfo:(AZErgoManga *)entity;
- (void) viewItem:(id)sender read:(AZErgoManga *)entity;

@end

@interface AZErgoMangaViewItem : NSCollectionViewItem

@property (nonatomic) AZErgoManga *representedObject;

@end
