//
//  MFMPlayerViewController.h
//  Moe FM
//
//  Created by Greg Wang on 12-4-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MoeFmPlayer.h"
#import "MoeFmAPI.h"

@interface MFMPlayerViewController : UIViewController <MoeFmPlayerDelegate, MoeFmAPIDelegate, UIAlertViewDelegate>

@property (assign, nonatomic) IBOutlet UINavigationItem *navTitle;
@property (assign, nonatomic) IBOutlet UILabel *songNameLabel;
@property (assign, nonatomic) IBOutlet UILabel *songInfoLabel;
@property (assign, nonatomic) IBOutlet UIProgressView *songProgressIndicator;
@property (assign, nonatomic) IBOutlet UIImageView *songArtworkImage;
@property (assign, nonatomic) IBOutlet UIActivityIndicatorView *songArtworkLoadingIndicator;
@property (assign, nonatomic) IBOutlet UIActivityIndicatorView *songBufferingIndicator;
@property (assign, nonatomic) IBOutlet UIButton *playButton;
@property (assign, nonatomic) IBOutlet UIButton *favButton;
@property (assign, nonatomic) IBOutlet UIButton *dislikeButton;
@property (assign, nonatomic) IBOutlet UIButton *nextButton;

- (IBAction)togglePlaybackState:(UIButton *)sender;
- (IBAction)toggleFavourite:(UIButton *)sender;
- (IBAction)toggleDislike:(UIButton *)sender;
- (IBAction)nextTrack:(UIButton *)sender;

@end