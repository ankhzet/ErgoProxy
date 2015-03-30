//
//  AZErgoUpdateChapter.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCommons.h"
#import "AZErgoChapterProtocol.h"

@interface AZErgoUpdateChapter : AZCoreDataEntity <AZErgoChapterProtocol>

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *genData;
@property (nonatomic) NSInteger volume;
@property (nonatomic) float idx;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSSet *downloads;

@property (nonatomic) NSString *mangaName;

@property (nonatomic, retain) AZErgoUpdateWatch *watch;

@property (nonatomic) AZErgoUpdateChapterDownloads state;

- (BOOL) isDummy;

@end

@interface AZErgoUpdateChapter (Formatting)

- (NSString *) formattedString;
- (NSString *) fullTitle;

@end