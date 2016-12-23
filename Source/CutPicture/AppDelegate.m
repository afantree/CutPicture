//
//  AppDelegate.m
//  CutPicture
//
//  Created by 阿凡树 on 2016/12/16.
//  Copyright © 2016年 阿凡树. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Sparkle/Sparkle.h>
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [SUUpdater sharedUpdater].sendsSystemProfile = YES;
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    [Fabric with:@[[Crashlytics class]]];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
