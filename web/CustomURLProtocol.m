//
//  CustomURLProtocol.m
//  HostWebView
//
//  Created by 陈建峰 on 16/4/1.
//  Copyright © 2016年 DouJinSDK. All rights reserved.
//

#import "CustomURLProtocol.h"
#define URLProtocolHandledKey @"URLProtocolHandledKey"

@interface CustomURLProtocol()
@property(nonatomic, retain) NSURLConnection *connection;
@end

@implementation CustomURLProtocol

#pragma mark - Host Dict

NSMutableDictionary *hostDict;

+ (void)addHost:(NSString*)host ip:(NSString *)ip {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hostDict = [[NSMutableDictionary alloc] init];
    });
    
    [hostDict setObject:ip forKey:host];
}

+ (void)removeHost:(NSString *)host {
    if (hostDict) {
        [hostDict removeObjectForKey:host];
    }
}

+ (NSURLRequest *)wrappedURLRequest:(NSURLRequest *)request {
    if ([request.URL host].length == 0) {
        return request;
    }
    
    NSMutableURLRequest *Myrequest = [request mutableCopy];
    
    //设置UA，伪装成是safari打开。 因为我的网站有判断，不允许safari以外的浏览器打开
    [Myrequest setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4" forHTTPHeaderField:@"User-Agent"];
    NSArray *allHosts = [hostDict allKeys];
    if (allHosts == nil || allHosts.count == 0) {
        [Myrequest setValue:request.URL.host forHTTPHeaderField:@"Host"];
    }
    for (NSString *host in allHosts) {
        NSString *originUrlString = [request.URL absoluteString];
        NSString *ip = [hostDict objectForKey:host];
        //查找请求链接的host是否在host文件中配置了
        NSRange hostRange = [originUrlString rangeOfString:host];
        //查找请求链接的host（可能是ip）是否在host文件中配置了。 用于给httpHeader加Host字段。有时候整个网页重定向后，请求链接就会变成是ip组成的host，这个时候也要给加Host头
        NSRange ipRange = [originUrlString rangeOfString:ip];
        
        if (hostRange.location != NSNotFound) {
            NSString *urlString = [originUrlString stringByReplacingCharactersInRange:hostRange withString:ip];
            NSURL *url = [NSURL URLWithString:urlString];
            Myrequest.URL = url;
            [Myrequest setValue:host forHTTPHeaderField:@"Host"];
            break;
        } else if (ipRange.location != NSNotFound) {
            [Myrequest setValue:host forHTTPHeaderField:@"Host"];
            break;
        } else {
            NSString *originHost = [request.URL host];
            [Myrequest setValue:originHost forHTTPHeaderField:@"Host"];
        }
    }
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    [Myrequest setAllHTTPHeaderFields:headers];
    
    return Myrequest.copy;
}

#pragma mark - Override Methods

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame))
    {
        // 看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return [self wrappedURLRequest:request];
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    //标示改request已经处理过了，防止无限循环。因为这里用NSURLConnection去请求数据，又会走一遍Protocol的流程
    NSMutableURLRequest *req = [[self class] wrappedURLRequest:[self request]].mutableCopy;
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:req];
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
    NSLog(@"startLoading data %@",[[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding]);
    NSLog(@"链接:url %@, headers:%@", req.URL, req.allHTTPHeaderFields);
}

- (void)stopLoading {
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"响应:%@", response);
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"数据:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    [self.client URLProtocol:self didLoadData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    request = [[self class] wrappedURLRequest:request];
    if (response) {
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}

/** HTTPS */

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount]== 0) {
        //NSURLCredential 这个类是表示身份验证凭据不可变对象。凭证的实际类型声明的类的构造函数来确定。
        NSURLCredential* cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:cre forAuthenticationChallenge:challenge];
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    else
    {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }    
}

@end
