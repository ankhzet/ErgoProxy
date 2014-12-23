//
//  AZChapter.h
//  ErgoProxy
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AZPageChapIDXDepth) {
	AZPageChapIDXDepthTillNone    = 0,
	AZPageChapIDXDepthTillPage    = 1 << 0,
	AZPageChapIDXDepthTillChapter = 1 << 1,
	AZPageChapIDXDepthTillVolume  = 1 << 2,
};

typedef struct {int volume; float chapter; int page; AZPageChapIDXDepth straight;} AZPageChapterIndex;

extern NSComparator AZChapter_pageOrderComparator;

@interface AZChapter : NSObject

@end

@interface AZChapter (Sorting)

+ (AZPageChapterIndex) decodeIndex:(NSString *)sample hasPageIDX:(AZPageChapIDXDepth)hasPage;

+ (NSArray *) sort:(NSArray *)array;
+ (NSArray *) sort:(NSArray *)array with:(NSComparator)sorter;

@end
