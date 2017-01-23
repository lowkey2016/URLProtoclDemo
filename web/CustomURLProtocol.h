//
//  CustomURLProtocol.h
//  HostWebView
//
//  Created by 陈建峰 on 16/4/1.
//  Copyright © 2016年 DouJinSDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomURLProtocol : NSURLProtocol
+ (void)addHost:(NSString*)host ip:(NSString *)ip;
+ (void)removeHost:(NSString *)host;
@end
