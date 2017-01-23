//
//  ViewController.m
//  web
//
//  Created by Jymn_Chen on 2017/1/22.
//  Copyright © 2017年 com.jymnchen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *tf;
@property (strong, nonatomic) IBOutlet UIWebView *web;
@property (strong, nonatomic) IBOutlet UIButton *loadBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tf.text = @"https://aso2.umlife.com";
//    _tf.text = @"https://portal.y.cn";
    _web.delegate = self;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSMutableURLRequest *req = webView.request.mutableCopy;
    NSLog(@"url = %@, headers = %@", req.URL, req.allHTTPHeaderFields);
    _loadBtn.hidden = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _loadBtn.hidden = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    _loadBtn.hidden = NO;
    NSLog(@"error = %@", error);
    [[[UIAlertView alloc] initWithTitle:@"出错了" message:error.description delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}

- (IBAction)loadAction:(id)sender {
    _loadBtn.userInteractionEnabled = NO;
    [_tf resignFirstResponder];
    NSURL *url = [NSURL URLWithString:_tf.text];
    [_web loadRequest:[NSURLRequest requestWithURL:url]];
    _loadBtn.userInteractionEnabled = YES;
}

@end
