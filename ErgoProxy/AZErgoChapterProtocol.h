//
//  AZErgoChapterProtocol.h
//  ErgoProxy
//
//  Created by Ankh on 19.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _IDX(_idx) ({(int)((_idx) * 100);})
#define _IDI(_idx) ({((_idx) / 100.f);})
#define _FRC(_idx) ({(_IDX(_idx) % 100);})

@protocol AZErgoChapterProtocol <NSObject>

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *genData;
@property (nonatomic) NSInteger volume;
@property (nonatomic) float idx;
@property (nonatomic, retain) NSDate *date;

@property (nonatomic) NSString *mangaName;


- (BOOL) isBonus;

@end

