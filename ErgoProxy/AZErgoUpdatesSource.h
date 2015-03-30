//
//  AZErgoUpdatesSource.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

#import "AZErgoUpdatesSourceDescription.h"

@class AZErgoUpdatesSource, AZErgoUpdateWatch, AZErgoUpdateChapter, TFHpple;
@protocol AZErgoUpdatesSourceDelegate <NSObject>

- (void) updatesSource:(AZErgoUpdatesSource *)source checkingWatch:(AZErgoUpdateWatch *)watch;
- (void) updatesSource:(AZErgoUpdatesSource *)source watch:(AZErgoUpdateWatch *)watch checked:(BOOL)hasUpdates;

@end

@protocol AZErgoUpdatesSourceParserProtocol <NSObject>

- (BOOL) correspondsTo:(NSString *)resoureURL;
- (NSString *) parseURL:(NSString *)url;
- (NSString *) genDataToFolder:(NSString *)genData;

- (NSSet *) parseTitles:(NSString *)string;

- (NSArray *) titlesFromDocument:(TFHpple *)document;
- (NSArray *) tagsFromDocument:(TFHpple *)document;
- (NSString *) annotationFromDocument:(TFHpple *)document;
- (NSString *) previewFromDocument:(TFHpple *)document;
- (NSArray *) chaptersFromDocument:(TFHpple *)document;
- (NSArray *) scansFromDocument:(TFHpple *)document;
- (NSDictionary *) entitiesFromDocument:(TFHpple *)document;
- (BOOL) isCompleteFromDocument:(TFHpple *)document;

- (NSString *) mappedTagName:(NSString *)name;

+ (float) chapterIdx:(NSString *)pattern;
+ (int) chapterVolume:(NSString *)pattern;
+ (NSString *) chapterTitle:(NSString *)pattern;
+ (NSString *) chapterTip:(NSString *)pattern;
+ (NSString *) chapter:(NSString *)pattern element:(NSUInteger)element;

@end


@interface AZErgoUpdatesSource : NSObject

@property (nonatomic) AZErgoUpdatesSourceDescription *descriptor;
@property int inProcess;

@property (nonatomic) id<AZErgoUpdatesSourceDelegate> delegate;

- (BOOL) checkAll:(void(^)(dispatch_block_t block))block;
- (void) checkWatch:(AZErgoUpdateWatch *)watch;
- (void) checkUpdate:(AZErgoUpdateChapter *)chapter withBlock:(void(^)(NSArray *scans))block;

@end

@interface AZErgoUpdatesSource (Commons)

+ (NSString *) serverURL;

+ (NSDictionary *) sharedSources;
+ (instancetype) sharedSource;
+ (BOOL) inProcess;
+ (NSUInteger) checkAll:(void(^)(dispatch_block_t block))block;

@end


extern const NSUInteger LABEL_ELEMENT_TITLE;
extern const NSUInteger LABEL_ELEMENT_VOLUME;
extern const NSUInteger LABEL_ELEMENT_CHAPTER;
extern const NSUInteger LABEL_ELEMENT_TIP;


@interface AZErgoUpdatesSource (SourceRelated) <AZErgoUpdatesSourceParserProtocol>

- (id) action:(NSString *)action request:(NSString *)genData;
- (id) infoAction:(AZErgoUpdateWatch *)watch;
- (id) scansAction:(AZErgoUpdateChapter *)chapter;
- (id) searchAction:(NSString *)query;

@end

@interface AZErgoUpdatesSourceDescription (DelayedBind)

- (AZErgoUpdatesSource *) relatedSource;

@end
