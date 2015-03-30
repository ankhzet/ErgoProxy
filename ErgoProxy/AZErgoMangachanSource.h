//
//  AZErgoMangachanSource.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesSource.h"

@interface AZErgoMangachanSource : AZErgoUpdatesSource

- (NSSet *) parseTitles:(NSString *)string;

@end
