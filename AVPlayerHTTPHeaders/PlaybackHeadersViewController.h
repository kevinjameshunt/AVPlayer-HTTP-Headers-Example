//
//  PlaybackHeadersViewController.h
//  AVPlayerHTTPHeaders
//
//  Created by Kevin Hunt on 2017-01-18.
//  Copyright © 2017 Prophet Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaybackHeadersViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *urlTextField;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;
@property (strong, nonatomic) IBOutlet UIView *playerView;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@end

