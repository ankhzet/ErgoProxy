//
//  AZEPAppCommons.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#ifndef ErgoProxy_AZEPAppCommons_h
#define ErgoProxy_AZEPAppCommons_h

#import "AZUtils.h"

#define API_ACTION_BASE_URL @"/a-p-i/ergo/"


#define DEF_USER_LOGIN @"user.credentials.login"
#define DEF_USER_PASSWORD @"user.credentials.password"

#define DEF_USER_LOGIN_AUTOMATICALY @"user.login.automatically"
#define DEF_USER_LOGIN_AS_GUEST @"user.login.asguest"


#define PREFS_PROXY_URL @"proxy.url"

#define PREFS_DOWNLOAD_PRESET  @"download.default.preset"
#define PREFS_DOWNLOAD_WIDTH   @"download.default.width"
#define PREFS_DOWNLOAD_HEIGHT  @"download.default.height"
#define PREFS_DOWNLOAD_QUALITY @"download.default.quality"
#define PREFS_DOWNLOAD_WEBTOON @"download.default.webtoon"

#define PREFS_DOWNLOAD_PER_STORAGE @"download.simultaneous"
#define PREFS_DOWNLOAD_FULL_RESOLVE @"download.full-resolve"


#define PREFS_COMMON_MANGA_STORAGE @"common.storage"
#define PREFS_COMMON_MANGA_DOWNLOADED @"common.downloaded"

#define PREFS_UI_DOWNLOADS_GROUPPED @"ui.downloads.groupped"
#define PREFS_UI_DOWNLOADS_HIDEFINISHED @"ui.downloads.hidefinished"
#define PREFS_UI_DOWNLOADS_SHOWUNFINISHED @"ui.downloads.showunfinished"


#define PREFS_WATCHER_AUTOCHECK_INTERVAL @"watcher.autocheck.interval"
#define PREFS_UI_WATCHER_HIDEFINISHED @"ui.watcher.hidefinished"

#define MANGA_STORAGE_FOLDERS [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)]

#endif
