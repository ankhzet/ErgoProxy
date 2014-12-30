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


@interface AZErgoUpdatesSource : NSObject

@property (nonatomic) AZErgoUpdatesSourceDescription *descriptor;
@property int inProcess;

@property (nonatomic) id<AZErgoUpdatesSourceDelegate> delegate;

- (BOOL) checkAll;
- (void) checkWatch:(AZErgoUpdateWatch *)watch;
- (void) checkWatch:(AZErgoUpdateWatch *)watch withBlock:(void(^)(AZErgoUpdateWatch *watch, NSUInteger updates))block;
- (void) checkUpdate:(AZErgoUpdateChapter *)chapter withBlock:(void(^)(AZErgoUpdateChapter *chapter, NSArray *scans))block;

@end

@interface AZErgoUpdatesSource (Commons)

+ (NSString *) serverURL;

+ (NSDictionary *) sharedSources;
+ (instancetype) sharedSource;
+ (BOOL) inProcess;
+ (NSUInteger) checkAll;

@end


extern const NSUInteger LABEL_ELEMENT_TITLE;
extern const NSUInteger LABEL_ELEMENT_VOLUME;
extern const NSUInteger LABEL_ELEMENT_CHAPTER;
extern const NSUInteger LABEL_ELEMENT_TIP;


@interface AZErgoUpdatesSource (SourceRelated)

- (id) action:(NSString *)action request:(NSString *)genData;
- (id) chaptersAction:(AZErgoUpdateWatch *)watch;
- (id) scansAction:(AZErgoUpdateChapter *)chapter;

- (NSArray *) chaptersFromDocument:(TFHpple *)document;
- (NSArray *) scansFromDocument:(TFHpple *)document;

+ (float) chapterIdx:(NSString *)pattern;
+ (int) chapterVolume:(NSString *)pattern;
+ (NSString *) chapterTitle:(NSString *)pattern;
+ (NSString *) chapterTip:(NSString *)pattern;
+ (NSString *) chapter:(NSString *)pattern element:(NSUInteger)element;

@end

@interface AZErgoUpdatesSourceDescription (DelayedBind)

- (AZErgoUpdatesSource *) relatedSource;

@end
