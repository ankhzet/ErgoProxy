//
//  AZErgoMangaTag.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

typedef NS_ENUM(NSUInteger, AZErgoTagGroup) {
	AZErgoTagGroupCommon = 0,
	AZErgoTagGroupComplete = 1,
	AZErgoTagGroupReaded = 2,
	AZErgoTagGroupDownloaded = 3,
	AZErgoTagGroupSuspended = 4,
	AZErgoTagGroupWebtoon = 5,
	AZErgoTagGroupAdult = 10,
};

@class AZErgoManga;

@interface AZErgoMangaTag : AZCoreDataEntity

@property (nonatomic, retain) NSString *tag;
@property (nonatomic, retain) NSString *annotation;
@property (nonatomic, retain) NSSet *manga;
@property (nonatomic, retain) NSNumber *guid;
@property (nonatomic) BOOL skip;

+ (instancetype) tagByGuid:(NSNumber *)guid;
+ (instancetype) tagByName:(NSString *)name;
+ (instancetype) tagWithName:(NSString *)name;
+ (instancetype) tagWithGuid:(NSNumber *)guid;

+ (NSString *) tagGroupName:(AZErgoTagGroup)group;
+ (NSArray *) taggedManga:(AZErgoTagGroup)guid;

@end

@interface AZErgoMangaTag (CoreDataGeneratedAccessors)

- (void) removeMangaObject:(AZErgoManga *)manga;
- (void) addMangaObject:(AZErgoManga *)manga;

@end
