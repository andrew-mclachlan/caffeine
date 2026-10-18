//
//  LCMenuIconView.h
//  Caffeine
//
//  Created by Tomas Franzén on 2009-09-04.
//  Copyright 2009 Lighthead Software. All rights reserved.
//  Modified 2026 by Andrew McLachlan
//

#import <Cocoa/Cocoa.h>


// Status bar item built on NSStatusBarButton. Left click performs the action,
// right click (or control/command-click) shows the menu, double click opens preferences.
@interface LCMenuIconView : NSObject {
	BOOL isActive;
	BOOL menuIsShown;
	NSStatusItem *statusItem;
	NSMenu *menu;
	NSImage *activeImage;
	NSImage *inactiveImage;
	NSImage *highlightImage;
	NSImage *highlightActiveImage;
	NSTimeInterval lastClick;
	SEL action;
	id target;
}

- (id)initWithStatusItem:(NSStatusItem *)item;
- (void)setActive:(BOOL)flag;
- (void)setMenu:(NSMenu *)m;
- (void)setAction:(SEL)a;
- (void)setTarget:(id)t;
@end
