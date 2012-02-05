//
//  comViewController.h
//  RockRadioCas
//
//  Created by Jan Damek on /52/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>


@class AVPlayer;
@class AVPlayerItem;

@interface comViewController : UIViewController {
    
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    
    UIButton *playButton;
    UIButton *stopButton;
    
    UILabel *isPlayingAdText;
    
	NSArray *adList;
    
}

@property (retain) IBOutlet UIButton *playButton;
@property (retain) IBOutlet UIButton *stopButton;

@property (retain) AVPlayer *player;
@property (retain) AVPlayerItem *playerItem;

@property (retain) IBOutlet UILabel *isPlayingAdText;

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;


@end
