//
//  AppDelegate.m
//  web
//
//  Created by Jymn_Chen on 2017/1/22.
//  Copyright © 2017年 com.jymnchen. All rights reserved.
//

#import "AppDelegate.h"
#import "CustomURLProtocol.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CustomURLProtocol addHost:@"portal.y.cn" ip:@"54.222.185.224"];
    [NSURLProtocol registerClass:[CustomURLProtocol class]];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    return YES;
}

@end
