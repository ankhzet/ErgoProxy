//
//  AZErgoProxifierAPI.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZJSONAPI.h"

@class AZDownload, AZErgoManga;

@interface AZErgoProxifierAPI : AZJSONAPI

- (BOOL) resolveStorage:(AZDownload *)download;
- (BOOL) aquireScanData:(AZDownload *)download;
- (BOOL) downloadScan:(AZDownload *)download;

- (BOOL) downloadPreview:(AZErgoManga *)manga atOrigin:(NSString *)serverURL;

@end
