//
//  BridgePushLinkViewController.m
//  iBeacon
//
//  Created by ySiggen on 02.04.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "BridgePushLinkViewController.h"
#import <HueSDK_iOS/HueSDK.h>

@interface BridgePushLinkViewController ()

@end

@implementation BridgePushLinkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil hueSDK:(PHHueSDK *)hueSdk delegate:(id<BridgePushLinkViewControllerDelegate>) delegate
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.phHueSDK = hueSdk;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Pushlinking

/*Start the pushlinking process*/
- (void)startPushLinking
{
    /*Register for notifications about pushlinking*/
    PHNotificationManager *phNotificationManager = [PHNotificationManager defaultManager];
    [phNotificationManager registerObject:self withSelector:@selector(authenticationSuccess) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(authenticationFailed) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(noLocalBridge) forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(buttonNotPressed:) forNotification:PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION];
    
    /*Call hue SDK to start pushlinking process*/
    [self.phHueSDK startPushlinkAuthentication];
}

/*Notification receiver : called when the pushlinking was successful*/
- (void)authenticationSuccess
{
    /*Deregister for all notifications*/
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    /*Inform delegate*/
    [self.delegate pushlinkSuccess];
}

/*Notification receiver : called when the pushlinking failed (time limit reached)*/
- (void)authenticationFailed
{
    /*Deregister for all notifications*/
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    /*Inform delegate*/
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN
                                                      code:PUSHLINK_TIME_LIMIT_REACHED
                                                  userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed : time limit reached" forKey:NSLocalizedDescriptionKey]]];
}

/*Notification receiver : called when the pushlinking failed (local connection to the bridge lost)*/
- (void)noLocalConnection
{
    /*Deregister for all notifications*/
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    /*Inform delegate*/
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN
                                                      code:PUSHLINK_NO_CONNECTION userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed : no local connection to bridge" forKey:NSLocalizedDescriptionKey]]];
}

/*Notification receiver : called when the pushlinking failed (address of local bridge not known)*/
- (void)noLocalBridge
{
    /*Deregister for all notifications*/
    [[PHNotificationManager defaultManager] deregisterObjectForAllNotifications:self];
    /*Inform delegate*/
    [self.delegate pushlinkFailed:[PHError errorWithDomain:SDK_ERROR_DOMAIN
                                                      code:PUSHLINK_NO_LOCAL_BRIDGE userInfo:[NSDictionary dictionaryWithObject:@"Authentication failed : no local bridge found" forKey:NSLocalizedDescriptionKey]]];
}

/**This is called when pushlinking is still ongoing but no button was pressed yet. @param notification : contains the pushlinking percentage which is passed*/
- (void)buttonNotPressed:(NSNotification *)notification
{
#warning Seems like the status bar (percentage bar) doesn't work!
    /*Update status bar with percentage (from notification)*/
    NSDictionary *dict = notification.userInfo;
    NSNumber *progressPercentage = [dict objectForKey:@"progressPercentage"];
    /*Convert percentage to the progressbar scale*/
    float progressBarValue = [progressPercentage floatValue] / 100.0f;
    NSLog(@"Progress bar : %f",progressBarValue);
    self.progressView.progress = (float)progressBarValue;
}

@end
