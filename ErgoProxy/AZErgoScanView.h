//
//  AZErgoScanView.h
//  ErgoProxy
//
//  Created by Ankh on 18.05.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AZErgoScanHelper : NSObject

@end


@interface AZErgoScanView : NSView

@property (nonatomic) NSUInteger gutter;
@property (nonatomic) NSInteger gutterEdge;

@property (nonatomic) NSUInteger scans;
@property (nonatomic) NSUInteger currentScan;


- (void) scan:(NSUInteger)scan cached:(AZErgoScanHelper *)helper;
- (void) scan:(NSUInteger)scan shown:(AZErgoScanHelper *)helper;

@end
