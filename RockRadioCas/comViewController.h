//
//  comViewController.h
//  RockRadioCas
//
//  Created by Jan Damek on /52/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class AVPlayer;
@class AVPlayerItem;

@interface comViewController : UIViewController {
    
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    
    UIButton *playButton;
    UIButton *stopButton;
    
    UILabel *nazevSkladbyLabel;
    UILabel *interpretLabel;
    
    NSTimer *_redrawTimer;
    
	NSArray *adList;
    
    NSURLConnection *xmlFile;
    NSXMLParser *rssParser;
    NSMutableArray *articles;
    NSMutableDictionary *item;
    NSString *currentElement;
    NSMutableString *ElementValue;
    BOOL errorParsing;  
    
    NSString *_nazevSkladby;
    NSString *_interpret;
    
}

@property (retain) IBOutlet UIButton *playButton;
@property (retain) IBOutlet UIButton *stopButton;

@property (retain) AVPlayer *player;
@property (retain) AVPlayerItem *playerItem;

@property (retain) IBOutlet UILabel *nazevSkladbyLabel;
@property (retain) IBOutlet UILabel *interpretLabel;

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (void)initPlayer;

- (void)parseXMLFileAtURL:(NSString *)URL;

@end
