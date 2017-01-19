//
//  PlaybackHeadersViewController.m
//  AVPlayerHTTPHeaders
//
//  Created by Kevin Hunt on 2017-01-18.
//  Copyright © 2017 Prophet Studios. All rights reserved.
//

#import "PlaybackHeadersViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerReverseProxy.h"

@interface PlaybackHeadersViewController () <UITextFieldDelegate>

@end

@implementation PlaybackHeadersViewController {
    AVPlayer *_avPlayer;
    AVPlayerReverseProxy *_playerReverseProxy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _playerReverseProxy = [[AVPlayerReverseProxy alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playButtonPressed:(id)sender {
    
    if (_avPlayer != NULL) {
        // Remove observers
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerReverseProxyDidReceiveHeadersNotification object:nil];
        
        // Stop the player first
        [_avPlayer pause];
        _avPlayer = nil;
        
        // Stop Player Proxy
        [_playerReverseProxy stopPlayerProxy];
        
        _textView.text = @"";
    }
    
    // Grab the URL for playback
    NSString *url = _urlTextField.text;
    
    // Get external domain to be used for the reverse proxy
    NSURL *externalUrl = [NSURL URLWithString:url];
    NSString *externalDomain = [externalUrl host];
    
    // Set up the reverse proxy by passing it the reverse host and setting the headers as needed
    NSDictionary *httpHeaders = [NSDictionary dictionaryWithObject:@"X-SOME-HEADER" forKey:@"Pragma"];
    [_playerReverseProxy addHttpHeaders:httpHeaders];
    [_playerReverseProxy startPlayerProxyWithReverseProxyHost:externalDomain];
    
    // Crete observer to receive header info from responses
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayerProxyReceivedHeadersNotification:) name:AVPlayerReverseProxyDidReceiveHeadersNotification object:nil];
    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Switch the URL with the local host so that it passes through the proxy
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    NSString *customUrl = [url stringByReplacingOccurrencesOfString:externalDomain withString:AVPlayerProxyLocalHost];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:customUrl] options:nil];
    
    // Create the player and add it to the playerView
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    _avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:_avPlayer];
    [playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
    playerLayer.frame = _playerView.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.needsDisplayOnBoundsChange = YES;
    [_playerView.layer addSublayer:playerLayer];
    [_avPlayer play];
    
    _textView.text = @"Starting Playback";
}

- (void)handlePlayerProxyReceivedHeadersNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get headers and corresponding URL from notification
        NSDictionary *httpHeaders = [[notification userInfo] objectForKey:AVPlayerReverseProxyNotificationHeadersKey];
        NSString *requestUrl =  [[notification userInfo] objectForKey:AVPlayerReverseProxyNotificationRequestURLKey];
        
        // Update UI
        NSString *headerText = [NSString stringWithFormat:@"URL: %@\nHeaders:%@\n\n\n", requestUrl, httpHeaders];
        _textView.text = [headerText stringByAppendingString:_textView.text];
    });
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_urlTextField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

@end
