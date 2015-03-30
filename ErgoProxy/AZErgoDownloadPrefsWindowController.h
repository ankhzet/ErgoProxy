//
//  AZErgoDownloadPrefsWindowController.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZSheetWindowController.h"

@class AZDownloadParams, AZErgoManga;
@interface AZErgoDownloadPrefsWindowController : AZSheetWindowController

- (AZDownloadParams *) aquireParams:(BOOL)useDefaults forManga:(AZErgoManga *)manga;

@end
