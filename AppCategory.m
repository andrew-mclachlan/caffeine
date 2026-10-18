//
//  AppCategory.m
//  Caffeine
//
//  Created by Tomas Franzén on 2008-06-04.
//  Copyright 2008 Lighthead Software. All rights reserved.
//  Modified 2026 by Andrew McLachlan
//

#import "AppCategory.h"
#import "AppDelegate.h"


@implementation NSApplication (AppCategory)


- (void)activateCaffeine:(NSScriptCommand*)command {
	NSNumber *duration = [[command arguments] objectForKey:@"duration"];
	if(duration)
		[(AppDelegate *)[self delegate] activateWithTimeoutDuration:[duration doubleValue]];
	else
		[(AppDelegate *)[self delegate] activate];
}

- (void)deactivateCaffeine:(NSScriptCommand*)command {
	[(AppDelegate *)[self delegate] deactivate];
}

- (BOOL)isCaffeineActive {
	return [(AppDelegate *)[self delegate] isActive];
}

@end
