//
//  AZErgoMangaProgress.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AZErgoManga;

@interface AZErgoMangaProgress : NSManagedObject

@property (nonatomic, retain) NSNumber * chapter;
@property (nonatomic, retain) NSNumber * page;
@property (nonatomic, retain) AZErgoManga *manga;

@end
