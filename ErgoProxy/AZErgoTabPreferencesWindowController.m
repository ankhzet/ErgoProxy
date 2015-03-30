//
//  AZErgoTabPreferencesWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 28.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTabPreferencesWindowController.h"

#define PARAM_ROW_HEIGHT 50

#define _TP_LABEL @"label"
#define _TP_VALUE @"value"
#define _TP_TYPE @"type"

#define TP_GROUP(_name, _params) @{}
#define TP_PARAM(_type, _label, _value) @{_TP_TYPE: @(_type), _TP_LABEL: (_label), _TP_VALUE: (_value)}

#define TP_CHECK 0
#define TP_TEXT  1

@interface AZErgoTabPreferencesWindowController ()

@property (weak) IBOutlet NSView *contentView;

@end

@implementation AZErgoTabPreferencesWindowController

- (void) test {
	id params = @{
								@"common": @{
										@"1:param1": TP_PARAM(TP_TEXT, @"Param 1", @100),
										@"2:param2": TP_PARAM(TP_CHECK, @"Param 2", @0),
										@"3:param3": TP_PARAM(TP_TEXT, @"Param 3", @"adds"),
										},
								@"prefs2": @{
										@"1:param1": TP_PARAM(TP_TEXT, @"Param 1", @0),
										},
								@"prefs3": @{
										@"1:param1": TP_PARAM(TP_CHECK, @"Param 1", @0),
										@"2:param2": TP_PARAM(TP_TEXT, @"Param 2", @551),
										@"3:param3": TP_PARAM(TP_CHECK, @"Param 3", @1),
										@"4:param4": TP_PARAM(TP_TEXT, @"Param 4", @100),
										},
								};

	[self showPreferences:params];
}

- (void) showPreferences:(NSDictionary *)preferences {
	[self showWithSetup:^AZDialogReturnCode(AZErgoTabPreferencesWindowController *c) {
		[self buildViewTree:preferences];
		return [self beginSheet];
	} andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, AZErgoTabPreferencesWindowController *controller) {
		if (code == AZDialogReturnCancel)
			return code;

		

		return code;
	}];
}

- (void) buildViewTree:(NSDictionary *)preferences {
	AZ_Mutable(Dictionary, *groups);
	for (NSString *groupName in [preferences allKeys]) {
    NSDictionary *group = preferences[groupName];

		groups[groupName] = [self buildGroup:group withName:groupName];
	}

	[self.contentView alignGroup:groups];
}

- (NSView *) buildGroup:(NSDictionary *)group withName:(NSString *)groupName {
	NSRect frame = NSMakeRect(0, 0, self.contentView.frame.size.width, [group count] * PARAM_ROW_HEIGHT);
	NSBox *box = [[NSBox alloc] initWithFrame:frame];
	[box setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	box.title = LOC_FORMAT(groupName) ?: groupName;

	AZ_Mutable(Dictionary, *params);
	for (NSString *paramName in group)
		params[paramName] = [self buildParam:group[paramName] withName:paramName];

	[box.contentView alignGroup:params];
	return box;
}

- (NSView *) buildParam:(NSDictionary *)param withName:(NSString *)paramName {
	NSString *labelTitle = param[_TP_LABEL];
	id value = param[_TP_VALUE];
	if (![value isKindOfClass:[NSString class]])
		value = [value stringValue] ?: @"";

	NSRect frame = NSMakeRect(0, 0, self.contentView.frame.size.width, PARAM_ROW_HEIGHT);
	NSView *row = [[NSView alloc] initWithFrame:frame];
	[row setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

	NSRect frame1, frame2;
	NSDivideRect(frame, &frame1, &frame2, 0.3, CGRectMinXEdge);

	NSTextField *c1label = [[NSTextField alloc] initWithFrame:frame1];
	[c1label setBordered:NO];
	c1label.drawsBackground = NO;
	c1label.alignment = NSRightTextAlignment;
	((NSCell *)c1label.cell).lineBreakMode = NSLineBreakByWordWrapping;
	c1label.stringValue = [NSString stringWithFormat:@"%@:", labelTitle];

	NSControl *c2control;

	switch ([param[_TP_TYPE] unsignedIntegerValue]) {
		case TP_CHECK: {
			NSButton *check = (id)(c2control = [[NSButton alloc] initWithFrame:frame2]);
			[check setButtonType:NSSwitchButton];
			[check setState:[value intValue]];
			break;
		}

		case TP_TEXT:
		default: {
			c2control = [[NSTextField alloc] initWithFrame:frame2];
			c2control.stringValue = value;
			break;
		}
	}

	[row alignGroup:NSDictionaryOfVariableBindings(c1label, c2control) options:AZAlignModeStickToBorder sizes:nil];
	return row;
}

- (BOOL) applyChanges {
	return YES;
}

@end
