//
//  AZErgoBrowserTab.h
//  ErgoProxy
//
//  Created by Ankh on 30.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoTabsComons.h"

@interface AZErgoBrowserTab : AZTabProvider

+ (AZErgoBrowserTab *) browserTab;

- (NSString *) loadedURI;

- (NSString *) title;

@end
