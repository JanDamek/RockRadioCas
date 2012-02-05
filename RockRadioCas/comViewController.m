#import "comViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

#pragma mark -
@interface comViewController (Player)
- (BOOL)isPlaying;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end

@implementation comViewController

@synthesize player, playerItem;
@synthesize isPlayingAdText;
@synthesize playButton, stopButton;

#pragma mark -
#pragma mark Movie controller methods
#pragma mark -

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

#pragma mark Play, Stop Buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    //    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    //    [toolbarItems replaceObjectAtIndex:0 withObject:stopButton];
    //    toolBar.items = toolbarItems;
    playButton.hidden = YES;
    stopButton.hidden = NO;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    //    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    //    [toolbarItems replaceObjectAtIndex:0 withObject:playButton];
    //    toolBar.items = toolbarItems;
    playButton.hidden = NO;
    stopButton.hidden = YES;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];        
	}
}

-(void)enablePlayerButtons
{
    self.playButton.enabled = YES;
    self.stopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.playButton.enabled = NO;
    self.stopButton.enabled = NO;
}

#pragma mark Scrubber control

#pragma mark Button Action Methods

- (IBAction)play:(id)sender
{  
	[player play];
	
    [self showStopButton];  
}

- (IBAction)pause:(id)sender
{
	[player pause];
    
    [self showPlayButton];
}

#pragma mark -
#pragma mark View Controller
#pragma mark -

- (void)viewDidUnload
{
    
    self.playButton = nil;
    self.stopButton = nil;
    self.isPlayingAdText = nil;
    
    [super viewDidUnload];
}

- (void)viewDidLoad
{    
  
    [super viewDidLoad];
    
    // init prehravace
    
    NSString *u = @"http://icecast1.play.cz:8000/casrock32aac";
    
    NSURL *url = [NSURL URLWithString:u];
    
    player = [[AVPlayer alloc] initWithURL:url];    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    [self.player removeObserver:self forKeyPath:kCurrentItemKey];
    [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
    [self.player removeObserver:self forKeyPath:kRateKey];
//	[player release]; 
//	[adList release];
	
//	[playButton release];
//	[stopButton release];
//	[isPlayingAdText release];
	
//    [super dealloc];
}

@end

@implementation comViewController (Player)

#pragma mark -

#pragma mark Player

- (BOOL)isPlaying
{
	return [player rate] != 0.f;
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification 
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self showPlayButton];
    
}


-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
//	[alertView release];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail 
         out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) 
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    
	[self enablePlayerButtons];
	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];            
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
	
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];	
		
              
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
    
}


@end
