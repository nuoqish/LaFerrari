//
//  AppDelegate.m
//  LaFerrari
//
//  Created by stanshen on 17/5/22.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "AppDelegate.h"

#import "KTInspectableProperties.h"
#import "KTColor.h"
#import "KTGradient.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)clearTempDirectory {
    NSFileManager   *fm = [NSFileManager defaultManager];
    NSURL           *tmpURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSArray         *files = [fm contentsOfDirectoryAtURL:tmpURL includingPropertiesForKeys:[NSArray array] options:0 error:NULL];
    
    for (NSURL *url in files) {
        [fm removeItemAtURL:url error:nil];
    }
}


@end
