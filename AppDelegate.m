//
//  AppDelegate.m
//  Caffeine
//
//  Created by Tomas Franzén on 2006-05-20.
//  Copyright 2006 Lighthead Software. All rights reserved.
//  Modified 2026 by Andrew McLachlan
//

#import "AppDelegate.h"
@import ServiceManagement;


@implementation AppDelegate

- (void)awakeFromNib {
	
	NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	menuView = [[LCMenuIconView alloc] initWithStatusItem:item];
	[menuView setTarget:self];
	[menuView setMenu:menu];
	[menuView setAction:@selector(toggleActive:)];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"SuppressLaunchMessage"]];
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressLaunchMessage"])
		[self showPreferences:nil];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"ActivateOnLaunch"])
		[self toggleActive:nil];
	
}


- (void)dealloc {
	[self endActivity];
	[menuView release];
	[timeoutTimer release];
	[super dealloc];
}


// Holding an activity keeps the display and system from idle sleeping. It is released
// automatically if the process exits, so a crash can't leave the Mac awake.
- (void)beginActivity {
	if(activity) return;
	activity = [[[NSProcessInfo processInfo] beginActivityWithOptions:(NSActivityIdleDisplaySleepDisabled | NSActivityIdleSystemSleepDisabled)
															   reason:@"Caffeine is active"] retain];
}

- (void)endActivity {
	if(!activity) return;
	[[NSProcessInfo processInfo] endActivity:activity];
	[activity release];
	activity = nil;
}


- (void)activateWithTimeoutDuration:(NSTimeInterval)interval {
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	if(interval > 0)
		timeoutTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timeoutReached:) userInfo:nil repeats:NO] retain];
	isActive = YES;
	[self beginActivity];
	[menuView setActive:isActive];
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:interval ? interval : -1], @"duration", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.lightheadsw.caffeine.activation" object:nil userInfo:info];	
}

- (void)activate {
	[self activateWithTimeoutDuration:0];	
}

- (void)deactivate {
	isActive = NO;
	[self endActivity];
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	[menuView setActive:isActive];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.lightheadsw.caffeine.deactivation" object:nil userInfo:nil];
}



- (IBAction)activateWithTimeout:(id)sender {
	NSInteger minutes = [(NSMenuItem*)sender tag];
	NSInteger seconds = minutes*60;
	if(seconds == -60) seconds = 2;
	if(minutes)
		[self activateWithTimeoutDuration:seconds];
	else
		[self activate];
}



- (void)toggleActive:(id)sender {
	if(timeoutTimer) [[timeoutTimer autorelease] invalidate];
	timeoutTimer = nil;
	
	if(isActive) {
		[self deactivate];
	} else {
		NSInteger defaultMinutesDuration = [[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultDuration"];
		NSInteger seconds = defaultMinutesDuration*60;
		if(seconds == -60) seconds = 2;
		if(defaultMinutesDuration)
			[self activateWithTimeoutDuration:seconds];
		else
			[self activate];
	}
}


- (void)timeoutReached:(NSTimer*)timer {
	[self deactivate];
}

- (BOOL)isActive {
	return isActive;
}

- (IBAction)showAbout:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:self];
}

- (IBAction)showPreferences:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[firstTimeWindow center];
	[firstTimeWindow makeKeyAndOrderFront:sender];
}


- (BOOL)startsAtLogin {
	return [[SMAppService mainAppService] status] == SMAppServiceStatusEnabled;
}

- (void)setStartsAtLogin:(BOOL)start {
	if(start == [self startsAtLogin]) return;
	
	NSError *error = nil;
	BOOL ok = start ? [[SMAppService mainAppService] registerAndReturnError:&error]
					: [[SMAppService mainAppService] unregisterAndReturnError:&error];
	if(!ok) NSLog(@"Caffeine: could not change login item: %@", error);
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self showPreferences:nil];
	return NO;
}

- (void)menuNeedsUpdate:(NSMenu *)m {
	if(isActive) {
		[infoMenuItem setHidden:NO];
		[infoSeparatorItem setHidden:NO];
		if(timeoutTimer) {
			NSTimeInterval left = [[timeoutTimer fireDate] timeIntervalSinceNow];
			if(left >= 3600)
				[infoMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"%02d:%02d left", @"Time remaining as hours:minutes"), (int)(left/3600), (int)(((int)left%3600)/60)]];
			else if(left >= 60)
				[infoMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d minutes left", @"Time remaining in minutes"), (int)(left/60)]];
			else
				[infoMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d seconds left", @"Time remaining in seconds"), (int)left]];
		}else{
			[infoMenuItem setTitle:NSLocalizedString(@"Caffeine is active", @"Menu status when active with no timeout")];
		}
	}else{
		[infoMenuItem setHidden:YES];
		[infoSeparatorItem setHidden:YES];
	}
}

@end
