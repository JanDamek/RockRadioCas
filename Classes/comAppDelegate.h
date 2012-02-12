//
//  comAppDelegate.h
//  RockRadioCas
//
//  Created by Jan Damek on /52/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "comViewController.h"

@interface comAppDelegate : UIResponder <UIApplicationDelegate>
//@interface comAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
    comViewController *mainComViewController;
    UIWindow *window; 
}

@property (nonatomic, retain) IBOutlet comViewController *mainComViewController;
@property (nonatomic, retain) IBOutlet UIWindow *window;           

@end
