//
//  AppDelegate.m
//  BioTechFinder
//
//  Created by Alex Blokker on 2/19/16.
//  Copyright © 2016 Blokkmani. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"

@interface AppDelegate () @end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	RootViewController *rootVC = [[RootViewController alloc] init];
	self.window = [UIWindow new];
	self.window.rootViewController = rootVC;
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
