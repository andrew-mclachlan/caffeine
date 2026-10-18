//
//  LCMenuIconView.m
//  Caffeine
//
//  Created by Tomas Franzén on 2009-09-04.
//  Copyright 2009 Lighthead Software. All rights reserved.
//  Modified 2026 by Andrew McLachlan
//

#import "LCMenuIconView.h"
#import "AppDelegate.h"


@implementation LCMenuIconView

- (id)initWithStatusItem:(NSStatusItem *)item {
	self = [super init];
	if(!self) return nil;
	
	statusItem = [item retain];
	activeImage = [[NSImage imageNamed:@"active"] retain];
	inactiveImage = [[NSImage imageNamed:@"inactive"] retain];
	highlightImage = [[NSImage imageNamed:@"highlighted"] retain];
	highlightActiveImage = [[NSImage imageNamed:@"highlightactive"] retain];
	
	NSStatusBarButton *button = [statusItem button];
	[button addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:NULL];
	[self updateImage];
	[button setTarget:self];
	[button setAction:@selector(buttonClicked:)];
	[button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
	return self;
}


- (void)dealloc {
	[[statusItem button] removeObserver:self forKeyPath:@"effectiveAppearance"];
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	[statusItem release];
	[menu release];
	[activeImage release];
	[inactiveImage release];
	[highlightImage release];
	[highlightActiveImage release];
	[super dealloc];
}


// The artwork is dark for a light menu bar and white for a dark one (or while the menu is open).
- (void)updateImage {
	NSStatusBarButton *button = [statusItem button];
	NSAppearanceName name = [[button effectiveAppearance] bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
	BOOL light = menuIsShown || [name isEqualToString:NSAppearanceNameDarkAqua];
	if(light)
		[button setImage:isActive ? highlightActiveImage : highlightImage];
	else
		[button setImage:isActive ? activeImage : inactiveImage];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateImage];
}

- (void)setActive:(BOOL)flag {
	isActive = flag;
	[self updateImage];
}


- (void)showMenu {
	// Attaching the menu only for the duration of the click keeps left click as a plain action.
	menuIsShown = YES;
	[self updateImage];
	[statusItem setMenu:menu];
	[[statusItem button] performClick:nil];
	[statusItem setMenu:nil];
	menuIsShown = NO;
	[self updateImage];
}


- (void)buttonClicked:(id)sender {
	NSEvent *e = [NSApp currentEvent];
	BOOL menuRequested = [e type] == NSEventTypeRightMouseUp || ([e modifierFlags] & (NSEventModifierFlagCommand | NSEventModifierFlagControl));
	if(menuRequested)
		return [self showMenu];
	
	if([e clickCount] >= 2) {
		// The first click of the double click already toggled; undo it and show preferences.
		[NSApp sendAction:action to:target from:self];
		[NSApp sendAction:@selector(showPreferences:) to:nil from:nil];
		return;
	}
	
	[NSApp sendAction:action to:target from:self];
}


- (void)setMenu:(NSMenu *)m {
	[menu autorelease];
	menu = [m retain];
}

- (void)setAction:(SEL)a {
	action = a;
}

- (void)setTarget:(id)t {
	target = t;
}

@end
