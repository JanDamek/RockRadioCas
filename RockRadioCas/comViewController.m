#import "comViewController.h"

#import <SystemConfiguration/SCNetworkReachability.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPVolumeView.h>
#import "Reachability.h"

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
@synthesize nazevSkladbyLabel, interpretLabel;
@synthesize playButton, stopButton, showVolumeButton, hideVolumeButton;

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

- (IBAction)showVolume:(id)sender
{
    [myVolumeView setHidden:NO];
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         myVolumeView.frame = CGRectMake(25, 360, 270, 22 );
                     } 
                     completion:^(BOOL finished){
                         NSLog(@"Done!");
                         showVolumeButton.hidden = YES;
                         hideVolumeButton.hidden = NO;                         
                     }];     
    
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

- (IBAction)hideVolume:(id)sender
{ 
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         myVolumeView.frame = CGRectMake(88, 440, 5, 22 );
                     } 
                     completion:^(BOOL finished){
                         [myVolumeView setHidden:YES];
                         showVolumeButton.hidden = NO;
                         hideVolumeButton.hidden = YES;                         
                     }];  
   
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
    if (player.status == AVPlayerStatusReadyToPlay)
    {	  
        [player play];
           
        [self doTimer];  
    }
    else
    {
        [self initPlayer];
        [player play];
        [self doTimer];
    }
	
    [self showStopButton];  
}

- (IBAction)pause:(id)sender
{
	[player pause];
    
    [self showPlayButton];
    
    [self doTimer];
    
}

#pragma mark -
#pragma mark View Controller
#pragma mark -

- (void)viewDidUnload
{
    
    self.playButton = nil;
    self.stopButton = nil;
    self.nazevSkladbyLabel = nil;
    self.interpretLabel = nil;
    
    [_redrawTimer invalidate];
    _redrawTimer = nil;
    
    [super viewDidUnload];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"File found and parsing started");
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *errorString = [NSString stringWithFormat:@"Error code %i", [parseError code]];
    NSLog(@"Error parsing XML: %@", errorString);
    [interpretLabel setText:@""];
    [nazevSkladbyLabel setText:@"Chyba XML"];
    
    
    errorParsing=YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    currentElement = [elementName copy];
    ElementValue = [[NSMutableString alloc] init];                
        
    if ([elementName isEqualToString:@"item"]) {
        item = [[NSMutableDictionary alloc] init];
        
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [ElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"TITLE"])
    {
        _nazevSkladby = [ElementValue copy];
    }
    else if ([elementName isEqualToString:@"ARTIST"])
    {
        _interpret = [ElementValue copy];
    }  
    
    if ([elementName isEqualToString:@"item"]) {
        [articles addObject:[item copy]];
    } else {
        [item setObject:ElementValue forKey:elementName];
    }
    
}

- (void)parseXMLFileAtURL:(NSString *)URL
{
    
    NSString *agentString = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:URL]];
    [request setValue:agentString forHTTPHeaderField:@"User-Agent"];
    xmlFile = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    
    articles = [[NSMutableArray alloc] init];
    errorParsing=NO;
    
    rssParser = [[NSXMLParser alloc] initWithData:xmlFile];
    [rssParser setDelegate:self];
    
    // You may need to turn some of these on depending on the type of XML file you are parsing
    [rssParser setShouldProcessNamespaces:NO];
    [rssParser setShouldReportNamespacePrefixes:NO];
    [rssParser setShouldResolveExternalEntities:NO];
    
    [rssParser parse];    
    
}

- (void)doTimer{
    // on timer 
    if (playButton.hidden == NO)
    {
        NSDate *now = [NSDate date];    
        [nazevSkladbyLabel setText:[[NSString alloc] initWithFormat:@"%@",now]];
        [interpretLabel setText:@""];
    }
    else
    {
        [self parseXMLFileAtURL:@"http://casrock.cz/nowplaying/rockonair.xml"];
        
        [nazevSkladbyLabel setText:_nazevSkladby];        
        [interpretLabel setText:_interpret];
    }
    
    if (player.status == AVPlayerStatusFailed)
    {
        [self pause:0];
    }      
    
}

- (void)_frameTimerFired:(NSTimer *)timer {
    [self doTimer];    
}


- (void)viewDidLoad
{    
  
    [super viewDidLoad];

    NSDictionary *userDefaultsDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"http://icecast1.play.cz:8000/casrock32aac", @"stream",
                                          nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];    
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    
    myVolumeView =
    [[MPVolumeView alloc] initWithFrame: CGRectMake(88, 440, 5, 22 )];
    [self.view addSubview: myVolumeView];
    myVolumeView.hidden = YES;
    
    // init prehravace
    

    [self initPlayer];
    
    _redrawTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                     target:self
                                                   selector:@selector(_frameTimerFired:)
                                                   userInfo:nil
                                                    repeats:YES];     
    if ([defaults boolForKey:@"auto_play"] == YES) {
       [self play:0];
    }
}

- (void)initPlayer
{
    if ((([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi)) || ([defaults boolForKey:@"only_wifi"] != YES))         
    {
    NSString *u=[defaults objectForKey:@"stream"];
    
//    NSString *u = @"http://icecast1.play.cz:8000/casrock32aac";
    
    NSURL *url = [NSURL URLWithString:u];
    
    player = [[AVPlayer alloc] initWithURL:url];    
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Chyba internetu"
                                                            message:@"WiFi není dostupné."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];        
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    [self.player removeObserver:self forKeyPath:kCurrentItemKey];
    [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
    [self.player removeObserver:self forKeyPath:kRateKey];

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
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
    
}


@end
