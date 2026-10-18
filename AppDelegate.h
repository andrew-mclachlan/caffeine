//
//  AppDelegate.h
//  Caffeine
//
//  Created by Tomas Franzén on 2006-05-20.
//  Copyright 2006 Lighthead Software. All rights reserved.
//  Modified 2026 by Andrew McLachlan
//

#import <Cocoa/Cocoa.h>
#import "LCMenuIconView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate> {
	BOOL isActive;
	id<NSObject> activity;
	NSTimer *timeoutTimer;
	
	LCMenuIconView *menuView;
	IBOutlet NSMenu *menu;
	IBOutlet NSWindow *firstTimeWindow;
	IBOutlet NSMenuItem *infoMenuItem;
	IBOutlet NSMenuItem *infoSeparatorItem;
}

- (IBAction)showAbout:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)activateWithTimeout:(id)sender;

- (void)activateWithTimeoutDuration:(NSTimeInterval)interval;
- (void)activate;
- (void)deactivate;
- (BOOL)isActive;
- (void)toggleActive:(id)sender;

@end
