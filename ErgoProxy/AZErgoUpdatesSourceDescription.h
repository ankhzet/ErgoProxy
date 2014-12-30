//
//  AZErgoUpdatesSourceDescription.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@interface AZErgoUpdatesSourceDescription : AZCoreDataEntity

@property (nonatomic, retain) NSString *serverURL;
@property (nonatomic, retain) NSSet *watches;

@end
