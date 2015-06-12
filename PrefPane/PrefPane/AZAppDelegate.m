//
//  AZAppDelegate.m
//  PrefPane
//
//  Created by Ankh on 01.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZAppDelegate.h"

#import "AZUtils.h"

#define PARAM_ROW_HEIGHT 24

#define _TP_LABEL @"label"
#define _TP_VALUE @"value"
#define _TP_TYPE @"type"

#define TP_GROUP(_name, _params) @{}
#define TP_PARAM(_type, _label, _value) @{_TP_TYPE: @(_type), _TP_LABEL: (_label), _TP_VALUE: (_value)}

#define TP_CHECK 0
#define TP_TEXT  1

@implementation AZAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];

//
//	id params = @{
//								@"common": @{
//										@"1:param1": TP_PARAM(TP_TEXT, @"Param 1", @100),
//										@"2:param2": TP_PARAM(TP_CHECK, @"Param 2", @0),
//										@"3:param3": TP_PARAM(TP_TEXT, @"Param 3", @"adds"),
//										},
//								@"prefs2": @{
//										@"1:param1": TP_PARAM(TP_TEXT, @"Param 1", @0),
//										},
//								@"prefs3": @{
//										@"1:param1": TP_PARAM(TP_CHECK, @"Param 1", @0),
//										@"2:param2": TP_PARAM(TP_TEXT, @"Param 2", @551),
//										@"3:param3": TP_PARAM(TP_CHECK, @"Param 3", @1),
//										@"4:param4": TP_PARAM(TP_TEXT, @"Param 4", @100),
//										},
//								};

	NSView *view = self.window.contentView;

	NSTextField *v1 = [NSTextField new];
	NSTextField *v2 = [NSTextField new];
	NSTextField *v3 = [NSTextField new];
	NSTextField *v4 = [NSTextField new];
	[v1 setStringValue:@"v1"];
	[v2 setStringValue:@"v2"];
	[v3 setStringValue:@"v3"];
	[v4 setStringValue:@"v4"];

	[view alignGroup:@{
										 @"v1": v1,
										 @"v2": v2,
										 @"v3": v3,
										 @"v4": v4,
										 }
					 options:AZAlignModeVertically
						 sizes:@{@"V": @{
												 @"v1": @20,
												 @"v2": @30,
												 @"v3": @15,
												 @"v4": @200,
												 }}];

//	[view addSubview:[self buildParam:TP_PARAM(TP_TEXT, @"Param 1", @"Some text") withName:@"1:param1" inSuperview:view]];

//	[self showPreferences:params];
}

- (void) showPreferences:(NSDictionary *)preferences {
	[self buildViewTree:preferences];
}

- (void) buildViewTree:(NSDictionary *)preferences {
	NSView *view = self.window.contentView;

	AZ_Mutable(Dictionary, *groups);
	for (NSString *groupName in [preferences allKeys]) {
    NSDictionary *group = preferences[groupName];

		groups[groupName] = [self buildGroup:group withName:groupName inSuperview:view];
	}

	[view alignGroup:groups];
}

- (NSView *) buildGroup:(NSDictionary *)group withName:(NSString *)groupName inSuperview:(NSView *)superview {
	NSRect frame = NSMakeRect(0, 0, superview.frame.size.width, [group count] * PARAM_ROW_HEIGHT);
	NSBox *box = [[NSBox alloc] initWithFrame:frame];
	[box setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	box.title = LOC_FORMAT(groupName) ?: groupName;

	AZ_Mutable(Dictionary, *params);
	for (NSString *paramName in group)
		params[paramName] = [self buildParam:group[paramName] withName:paramName inSuperview:box.contentView];

	[box.contentView alignGroup:params];
	return box;
}

- (NSView *) buildParam:(NSDictionary *)param withName:(NSString *)paramName inSuperview:(NSView *)superview {
	NSString *labelTitle = param[_TP_LABEL];
	id value = param[_TP_VALUE];
	if (![value isKindOfClass:[NSString class]])
		value = [value stringValue] ?: @"";

	NSRect frame = superview.frame;
	frame.size.height = PARAM_ROW_HEIGHT;

	NSView *row = [[NSView alloc] initWithFrame:frame];
//	[row setAutoresizesSubviews:NO];
	[row setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];

	NSRect frame1, frame2;
	NSDivideRect(frame, &frame1, &frame2, (int)(frame.size.width * 0.3), CGRectMinXEdge);

	frame1 = NSInsetRect(frame1, 10, 0);
	frame2 = NSInsetRect(frame2, 10, 0);
	NSDictionary *sizes = @{
													@"V": @{
															@"c1label": @(PARAM_ROW_HEIGHT),
															@"c2control": @(PARAM_ROW_HEIGHT),
															},
													@"H": @{
															@"c1label": [NSString stringWithFormat:@"%@", @((int)frame1.size.width)],
//															@"c2control": [NSString stringWithFormat:@"%@", @(frame2.size.width)],
															},
													};

	NSTextField *c1label = [[NSTextField alloc] initWithFrame:frame1];
	NSCell *cell = c1label.cell;
//	[c1label setBordered:NO];
//	c1label.drawsBackground = NO;
	c1label.alignment = NSRightTextAlignment;
	cell.lineBreakMode = NSLineBreakByWordWrapping;
	c1label.stringValue = [NSString stringWithFormat:@"%@:", labelTitle];
	[c1label setEditable:NO];
	[cell setUsesSingleLineMode:YES];

	NSControl *c2control;

	switch ([param[_TP_TYPE] unsignedIntegerValue]) {
		case TP_CHECK: {
			NSButton *check = (id)(c2control = [[NSButton alloc] initWithFrame:frame2]);
			[check setButtonType:NSSwitchButton];
			[check setState:[value intValue]];
			[check setTitle:@""];
			[(id)check.cell setUsesSingleLineMode:YES];
			break;
		}

		case TP_TEXT:
		default: {
			c2control = [[NSTextField alloc] initWithFrame:frame2];
			c2control.stringValue = value;
			[(id)c2control.cell setUsesSingleLineMode:YES];
			break;
		}
	}

	[row alignGroup:NSDictionaryOfVariableBindings(c1label, c2control) options:0 sizes:sizes];

//	[row addConstraint:[NSLayoutConstraint constraintWithItem:c1label
//																									attribute:NSLayoutAttributeBaseline
//																									relatedBy:NSLayoutRelationEqual
//
//																										 toItem:c2control
//																									attribute:NSLayoutAttributeBaseline
//
//																								 multiplier:1
//																									 constant:0]];

	return row;
}



@end
