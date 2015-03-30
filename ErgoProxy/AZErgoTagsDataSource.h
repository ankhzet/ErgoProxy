//
//  AZErgoTagsDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZGroupableDataSource.h"
#import "AZErgoMangaCommons.h"

@protocol AZErgoTagsDataSourceDelegate <NSObject>

- (void) tagSelected:(AZErgoMangaTag *)tag;
- (void) tagDeleted:(AZErgoMangaTag *)tag;

@end

@interface AZErgoTagsDataSource : AZGroupableDataSource

@end
