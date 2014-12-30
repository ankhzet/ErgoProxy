//
//  AZErgoManualSchedulerWindowController.h
//  ErgoProxy
//
//  Created by Ankh on 29.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZSheetWindowController.h"

@interface AZErgoManualSchedulerWindowController : AZSheetWindowController

@property (nonatomic) BOOL isUsingDefault;
@property (nonatomic) NSString *mangaDirectory;
@property (nonatomic) float mangaChapter;
@property (nonatomic) NSArray *scansList;

@end
