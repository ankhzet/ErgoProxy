//
//  AZEPAppCommons.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#ifndef ErgoProxy_AZEPAppCommons_h
#define ErgoProxy_AZEPAppCommons_h

#define API_ACTION_BASE_URL @"%@/a-p-i/ergo/"

#define PREF_SAVE_STR(_string, _pref_key) \
[[NSUserDefaults standardUserDefaults] setObject:(_string) forKey:(_pref_key)];

#define PREF_SAVE_BOOL(_bool, _pref_key) \
[[NSUserDefaults standardUserDefaults] setBool:!!_bool forKey:(_pref_key)];

#define PREF_SAVE_INT(_int, _pref_key) \
[[NSUserDefaults standardUserDefaults] setInteger:_int forKey:(_pref_key)];

#define PREF_SAVE_UI_STR(_string, _pref_key) \
PREF_SAVE_STR((_string).stringValue, _pref_key)

#define PREF_SAVE_UI_INT(_integer, _pref_key) \
PREF_SAVE_INT((_integer).integerValue, _pref_key)

#define PREF_SAVE_UI_BOOL(_checkbox, _pref_key) \
PREF_SAVE_BOOL(([(_checkbox) state] == NSOnState), _pref_key)

#define PREF_STR(_key)\
({id value = [[NSUserDefaults standardUserDefaults] stringForKey:(_key)]; (value != nil) ? value : @"";})

#define PREF_BOOL(_key)\
({[[NSUserDefaults standardUserDefaults] boolForKey:(_key)];})

#define PREF_INT(_key)\
({[[NSUserDefaults standardUserDefaults] integerForKey:(_key)];})


#define DEF_USER_LOGIN @"user.credentials.login"
#define DEF_USER_PASSWORD @"user.credentials.password"

#define DEF_USER_LOGIN_AUTOMATICALY @"user.login.automatically"
#define DEF_USER_LOGIN_AS_GUEST @"user.login.asguest"


#define PREFS_PROXY_URL @"proxy.url"

#define PREFS_DOWNLOAD_WIDTH   @"download.default.width"
#define PREFS_DOWNLOAD_HEIGHT  @"download.default.height"
#define PREFS_DOWNLOAD_QUALITY @"download.default.quality"
#define PREFS_DOWNLOAD_WEBTOON @"download.default.webtoon"
#define PREFS_DOWNLOAD_PER_STORAGE @"download.simultaneous"


#define PREFS_COMMON_MANGA_STORAGE @"common.storage"

#define PREFS_UI_DOWNLOADS_GROUPPED @"ui.downloads.groupped"
#define PREFS_UI_DOWNLOADS_HIDEFINISHED @"ui.downloads.hidefinished"


#define PREFS_WATCHER_AUTOCHECK_INTERVAL @"watcher.autocheck.interval"
#define PREFS_UI_WATCHER_HIDEFINISHED @"ui.watcher.hidefinished"


#endif
