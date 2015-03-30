//
//  CustomDictionary.m
//  ErgoProxy
//
//  Created by Ankh on 12.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "CustomDictionary.h"

@implementation RootDictionary @end
@implementation GroupsDictionary @end
@implementation ItemsDictionary @end


@implementation CustomDictionary

+ (instancetype) custom:(id)owner {
	CustomDictionary *dictionary = [self new];
	dictionary->owner = owner;
	return dictionary;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	dictionary = [NSMutableDictionary dictionary];
	return self;
}
- (void) setObject:(id)object forKeyedSubscript:(id<NSCopying>)key {
	dictionary[key] = object;
}
- (id) objectForKeyedSubscript:(id)key {
	return dictionary[key];
}
- (NSUInteger) count {
	return [dictionary count];
}
- (NSArray *) allKeys {
	return [dictionary allKeys];
}
- (NSArray *) allValues {
	return [dictionary allValues];
}

- (NSArray *) allKeysForObject:(id)object {
	return [dictionary allKeysForObject:object];
}

+ (BOOL) isDictionary:(id)object {
	return [object isKindOfClass:self];
}
//
//#pragma mark -
//#pragma mark NSPasteboardWriting support
//
//static NSString *CDictionaryType = @"AZ_CDictionaryType";
//
//- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
//
//	return @[CDictionaryType];
//}
//
//- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
//	if ([type isEqualToString:NSPasteboardTypeString]) {
//		return 0;
//	}
//	// Everything else is delegated to the image
//	if ([self.image respondsToSelector:@selector(writingOptionsForType:pasteboard:)]) {
//		return [self.image writingOptionsForType:type pasteboard:pasteboard];
//	}
//
//	return 0;
//}
//
//- (id)pasteboardPropertyListForType:(NSString *)type {
//	if ([type isEqualToString:NSPasteboardTypeString]) {
//		return self.name;
//	} else {
//		return [self.image pasteboardPropertyListForType:type];
//	}
//}
//
//#pragma mark -
//#pragma mark  NSPasteboardReading support
//
//+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
//	// We allow creation from URLs so Finder items can be dragged to us
//	return [NSArray arrayWithObjects:(id)kUTTypeURL, NSPasteboardTypeString, nil];
//}
//
//+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
//	if ([type isEqualToString:NSPasteboardTypeString] || UTTypeConformsTo((CFStringRef)type, kUTTypeURL)) {
//    return NSPasteboardReadingAsString;
//	} else {
//    return NSPasteboardReadingAsData;
//	}
//}
//
//- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
//	// See if an NSURL can be created from this type
//	if (UTTypeConformsTo((CFStringRef)type, kUTTypeURL)) {
//		// It does, so create a URL and use that to initialize our properties
//		NSURL *url = [[[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
//		self = [super init];
//		self.name = [url lastPathComponent];
//		// Make sure we have a name
//		if (self.name == nil) {
//			self.name = [url path];
//			if (self.name == nil) {
//				self.name = @"Untitled";
//			}
//		}
//		self.selectable = YES;
//
//		// See if the URL was a container; if so, make us marked as a container too
//		NSNumber *value;
//		if ([url getResourceValue:&value forKey:NSURLIsDirectoryKey error:NULL] && [value boolValue]) {
//			self.container = YES;
//			self.expandable = YES;
//		} else {
//			self.container = NO;
//			self.expandable = NO;
//		}
//
//		NSImage *localImage;
//		if ([url getResourceValue:&localImage forKey:NSURLEffectiveIconKey error:NULL] && localImage) {
//			self.image = localImage;
//		}
//
//	} else if ([type isEqualToString:NSPasteboardTypeString]) {
//		self = [super init];
//		self.name = propertyList;
//		self.selectable = YES;
//	} else {
//		NSAssert(NO, @"internal error: type not supported");
//	}
//	return self;
//}


@end
