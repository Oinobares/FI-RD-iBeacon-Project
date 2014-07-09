//
//  AppDelegate.m
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "AppDelegate.h"

/*Importing View Controllers*/
#import "WelcomeViewController.h"
#import "HueControlViewController.h"
#import "LoadingViewController.h"

#import "BeaconControl.h"

@import CoreBluetooth;

@interface AppDelegate  () <UIApplicationDelegate, CLLocationManagerDelegate>

@property UINavigationController *navigationController;

/*Bluetooth manager*/
@property (nonatomic, strong) CBCentralManager *bluetoothManager;

/*Beacon control class*/
@property (nonatomic, strong) BeaconControl *beaconControl;

/*View controllers*/
@property (nonatomic, strong) WelcomeViewController *welcomeView;
@property (nonatomic, strong) HueControlViewController *hueControl;
@property (nonatomic, strong) BridgePushLinkViewController *pushLinkViewController;
@property (nonatomic, strong) BridgeSelectionViewController *bridgeSelectionViewController;
@property (nonatomic, strong) LoadingViewController *loadingView;

/*Upnp Bridge search*/
@property (nonatomic, strong) PHBridgeSearching *bridgeSearch;

/*Hue alerts*/
@property (nonatomic, strong) UIAlertView *noConnectionAlert;
@property (nonatomic, strong) UIAlertView *noBridgeFoundAlert;
@property (nonatomic, strong) UIAlertView *authenticationFailedAlert;

@end

@implementation AppDelegate

@synthesize pushLinkViewController;
@synthesize bridgeSelectionViewController;
@synthesize inRegion;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*Set BOOL checking access over Hue and Sphero system to false at app launching*/
    self.didPresentHueView = NO;
    self.didPresentSpheroView = NO;
    
    /*Test if bluetooth available (system send a notification asking to enable BT if it's off)*/
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:nil queue: nil];
    
    /*Init locationManager (necessary to actually monitor the region)*/
    self.beaconControl = [[BeaconControl alloc] init];
    [self.beaconControl initLocationManager];
    
    /*Necessary for the notification/alert!*/
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    /*Create HueSDK instance*/
    self.phHueSDK = [[PHHueSDK alloc] init];
    [self.phHueSDK startUpSDK];
    [self.phHueSDK enableLogging:YES];
    
    /***************************************************
     The SDK will send the following notifications in response to events:
     
     - LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that the bridge heartbeat occurred and the bridge resources cache data has been updated
     
     - NO_LOCAL_CONNECTION_NOTIFICATION
     This notification will notify that there is no connection with the bridge
     
     - NO_LOCAL_AUTHENTICATION_NOTIFICATION
     This notification will notify that there is no authentication against the bridge
     *****************************************************/
    PHNotificationManager *phNotificationManager = [PHNotificationManager defaultManager];
    [phNotificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [phNotificationManager registerObject:self withSelector:@selector(notAuthenticated) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    
    return YES;
}

//- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
//{
//    //If app is in foreground, an alert will be shown
//    NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Title for cancel button in local notification");
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil, nil];
//    [alert show];
//    NSLog(@"Alert of App in foreground. AppDel");//TEST
//}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    /*Stop heartbeat*/
    [self disableLocalHeartbeat];
    
    /*Remove any open popups*/
    if (self.noConnectionAlert != nil)
    {
        [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:NO];
        self.noConnectionAlert = nil;
    }
    if (self.noBridgeFoundAlert != nil)
    {
        [self.noBridgeFoundAlert dismissWithClickedButtonIndex:[self.noBridgeFoundAlert cancelButtonIndex] animated:NO];
        self.noBridgeFoundAlert = nil;
    }
    if (self.authenticationFailedAlert != nil)
    {
        [self.authenticationFailedAlert dismissWithClickedButtonIndex:[self.authenticationFailedAlert cancelButtonIndex] animated:NO];
        self.authenticationFailedAlert = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    /*Start heartbeat*/
    [self enableLocalHeartbeat];
    /*Start monitoring for Zone 1 again (used in WelcomeViewController)*/
    [self.beaconControl startMonitoringBeaconRegion];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    /*Lose control of the Hue and Sphero control view as the app closes*/
    self.didPresentHueView = NO;
    self.didPresentSpheroView = NO;
    /*Stop monitoring for Zone 1 (used to check if the user is in the area at the WelcomeViewController*/
    [self.beaconControl stopMonitoringBeaconRegion];
}

#pragma mark - Location Manager

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    /*if App is not running and a user gets in or out of the region, CoreLocation will launch the app to call this method and send a notification.*/
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    if (state == CLRegionStateInside)
    {   /*If the user is in the monitored region, a notification is sent and a Bool is set to YES for giving access to a Segue (in WelcomeViewController)*/
        notification.alertBody = NSLocalizedString(@"Bienvenue en C10.12", @"");
        self.inRegion = YES;
    }
    else if (state == CLRegionStateOutside)
    {   /*If the user is outside of the monitored region, a notification is sent and the Bool giving access to a Segue (in WelcomeViewController) is set to NO*/
        notification.alertBody = NSLocalizedString(@"Vous partez? Avez-vous tout éteint?", @"");
        self.inRegion = NO;
    }
    else
    {
        return;
    }
    
    /*If the app is in foreground, it will get a callback to application:didReceiveNotification. If it is not, iOS will display the notification.*/
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    /*Notification update to refresh toolbar in Welcome view controller*/
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshView" object:nil];
}

#pragma mark - HueSDK

/*Notification receiver for successful local connection*/
- (void)localConnection
{
    /*Check current connection state*/
    [self checkConnectionState];
}

/*Notification receiver for failed local connection*/
- (void)noLocalConnection
{
    /*Check current connection state*/
    [self checkConnectionState];
}

/*Notification receiver for failed local authentification*/
- (void)notAuthenticated
{
    /*Move to detection table view if local authentication failed*/
    #warning hue no connection : go back to detection table is not working!
    NSString *storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"Detection"];
    //[self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
    
    NSLog(@"Not authenticated : going to Detection Table View (called in AppDelegate)!");//TEST
    
    /*Remove no connection alert*/
    if (self.noConnectionAlert != nil)
    {
        [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
        self.noConnectionAlert = nil;
    }
    /*Start local authentication process*/
    [self performSelector:@selector(doAuthentication) withObject:nil afterDelay:0.5];
}

/*Check if connected to the bridge locally, if not : show an error (if not already shown)*/
- (void)checkConnectionState
{
    if (!self.phHueSDK.localConnected)
    {
#warning hue no connection : go back to detection table is not working!
        /*Go back to detection table view if not connected (when on hue control view)*/
        if (self.hueControl.isViewLoaded && self.hueControl.view.window) {
            NSString *storyboardName = @"Main";
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
            UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"Detection"];
            [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
            NSLog(@"Not authenticated : going to Detection Table View from Hue Control (called in AppDelegate)!");//TEST
        }
        
        /*Not connected, show connection popup*/
        if (self.noConnectionAlert == nil)
        {
            /*Showing popup so remove this view*/
            [self removeLoadingView];
            [self showNoConnectionDialog];
            NSLog(@"Check connection state : show no connection dialog (called in AppDelegate)!");//TEST
        }
    }
    else
    {
        /*A connection is made, remove popups and loading screen*/
        if (self.noConnectionAlert != nil)
        {
            [self.noConnectionAlert dismissWithClickedButtonIndex:[self.noConnectionAlert cancelButtonIndex] animated:YES];
            self.noConnectionAlert = nil;
        }
        [self removeLoadingView];
    }
}

/*Show more connection options for the first no connection alert*/
- (void)showNoConnectionDialog
{
    self.noConnectionAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pas de connexion", @"No connection alert title")
                                                        message:NSLocalizedString(@"Connexion au Bridge non établie", @"No connection alert message")
                                                       delegate:self
                                              cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Reconnecter", @"No connection alert reconnect button"), NSLocalizedString(@"Trouver nouveau Bridge", @"No connection find new bridge button"), NSLocalizedString(@"Annuler", @"No connection canel button"), nil];
    self.noConnectionAlert.tag = 1;
    [self.noConnectionAlert show];
}
             

#pragma mark - Heartbeat control
             
/*Start local heartbeat with 10 sec interval*/
- (void)enableLocalHeartbeat
{
    /*See if we have a bridge connected*/
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil)
    {
        /*Show loading view*/
        [self showLoadingViewWithText:(@"Connexion...")];
        /*Enable heartbeat with interval of 10 sec*/
        [self.phHueSDK enableLocalConnectionUsingInterval:10];
    }
    else
    {
        /*Automatically start searching for bridges*/
        [self searchForBridgeLocal];
    }
}

/*Stop local heartbeat*/
- (void)disableLocalHeartbeat
{
    [self.phHueSDK disableLocalConnection];
}

#pragma mark - Bridge searching and selection

/*Search for bridges using UPnP and portal discovery, give error if not found*/
- (void)searchForBridgeLocal
{
    /*Stop heartbeat*/
    [self disableLocalHeartbeat];
    
    /*Show search screen*/
    [self showLoadingViewWithText:NSLocalizedString(@"Recherche...", @"Searching for bridges text")];
    
    /*Start search*/
    self.bridgeSearch = [[PHBridgeSearching alloc] initWithUpnpSearch:YES andPortalSearch:YES];
    [self.bridgeSearch startSearchWithCompletionHandler:^(NSDictionary *bridgesFound){
        /*Remove loading view because of search is complete*/
        [self removeLoadingView];
        
        /*Check for results*/
        if (bridgesFound.count > 0)
        {
            /*Results were found : show options to user*/
            self.bridgeSelectionViewController = [[BridgeSelectionViewController alloc] initWithNibName:@"BridgeSelectionViewController" bundle:[NSBundle mainBundle] bridges:bridgesFound delegate:self];
            [self.window addSubview:bridgeSelectionViewController.view];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bridgeSelectionViewController];
            /*Present list of bridges in order to have one selected by user*/
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        }
        else
        {
            /*No bridge found : show this to user*/
            self.noBridgeFoundAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pas de Bridge trouvé", @"No bridge found alert title")
                                                                 message:NSLocalizedString(@"Aucun Bridge n'a été trouvé", @"No bridge found alert message")
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"Réessayer", @"No bridge found alert retry button"), NSLocalizedString(@"Annuler", @"No bridge found alert cancel button"), nil];
            self.noBridgeFoundAlert.tag = 1;
            [self.noBridgeFoundAlert show];
        }
    }];
}
             
/*Invoked when a bridge is selected*/
- (void)bridgeSelectionWithIpAddress:(NSString *)ipAddress andMacAddress:(NSString *)macAddress
{
    /*Remove selection view controller*/
    [self.bridgeSelectionViewController.view removeFromSuperview];
    self.bridgeSelectionViewController = nil;
    
    /*Show connection view while we try to connect to the bridge*/
    [self showLoadingViewWithText:NSLocalizedString(@"Connexion...", @"")];
    
    /*Set SDK to use bridge and our default username (which should be the same across all apps, so pushlinking is only required once)*/
//    NSString *username = [PHUtilities whitelistIdentifier];
    
    /*Set username, IP and MAC as bridge properties that the SDK will use*/
    [self.phHueSDK setBridgeToUseWithIpAddress:ipAddress macAddress:macAddress];
    
    /*Start local heartbeat again*/
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}
             
#pragma mark - Bridge authentication

/*Start local authentication process*/
- (void)doAuthentication
{
    /*Disable heartbeat*/
    [self disableLocalHeartbeat];
    
    /*Create an interface for the pushlinking (to be certain that we own the bridge)*/
    self.pushLinkViewController = [[BridgePushLinkViewController alloc] initWithNibName:@"BridgePushLinkViewController" bundle:[NSBundle mainBundle] hueSDK:self.phHueSDK delegate:self];
    [self.window addSubview:pushLinkViewController.view];
    [self.pushLinkViewController startPushLinking];
    [self.navigationController presentViewController:self.pushLinkViewController animated:YES completion:^{
        /*Start the pushlinking*/
        //[self.pushLinkViewController startPushLinking];
    }];
}

/*Delegate method for BridgePusLinkViewController : invoked if pushlinking was successful*/
- (void)pushlinkSuccess
{
    /*Remove pushlinking view controller*/
    [self.pushLinkViewController.view removeFromSuperview];
    self.pushLinkViewController = nil;
    
    /*Start local heartbeat*/
    [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
}

/*Delegate method for BridgePushLinkViewController : invoked if psuhlinking was not successful*/
- (void)pushlinkFailed:(PHError *)error
{
    /*Remove pushlinking view controller*/
    [self.pushLinkViewController.view removeFromSuperview];
    self.pushLinkViewController = nil;
    
    /*Check which error occured*/
    if (error.code == PUSHLINK_NO_CONNECTION)
    {
        /*No local connection to the bridge*/
        [self noLocalConnection];
        
        /*Start local heartbeat (in order to see when connection comes back*/
        [self performSelector:@selector(enableLocalHeartbeat) withObject:nil afterDelay:1];
    }
    else
    {
        /*Bridge button not pressed in time*/
        self.authenticationFailedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentification échouée", @"Authentication failed alert title")
                                                                    message:NSLocalizedString(@"Assurez-vous d'avoir appuyé sur le bouton du Bridge dans un laps de 30 secondes", @"Authentication failed alert message")
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"Réessayer", @"Authentication failed alert retry button"), NSLocalizedString(@"Annuler", @"Authentication failed cancel button"), nil];
        [self.authenticationFailedAlert show];
    }
}

#pragma mark - Alerview delegate

/*Handling events when a specific button is clicked in the multiple notifications for the Hue system*/
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.noConnectionAlert && alertView.tag == 1)
    {
        /*No connection alert with option to reconnect or more options*/
        self.noConnectionAlert = nil;
        
        if (buttonIndex == 0)
        {
            /*Retry : just wait for the heartbeat to finish*/
            [self showLoadingViewWithText:@"Connexion..."];
        }
        else if (buttonIndex == 1)
        {
            /*Find new bridge button*/
            [self searchForBridgeLocal];
        }
        else if (buttonIndex == 2)
        {
            /*Cancel and disable local heartbeat*/
            [self disableLocalHeartbeat];
        }
    }
    else if (alertView == self.noBridgeFoundAlert && alertView.tag == 1)
    {
        /*"No bdriges found locally" alert*/
        self.noBridgeFoundAlert = nil;
        
        if (buttonIndex == 0)
        {
            /*Retry*/
            [self searchForBridgeLocal];
        }
        else if (buttonIndex == 1)
        {
            /*Cancel and disable local heartbeat*/
            [self disableLocalHeartbeat];
        }
    }
    else if (alertView == self.authenticationFailedAlert)
    {
        /*This is the alert which is shown when local pushlinking authentication has failed*/
        self.authenticationFailedAlert = nil;
        
        if (buttonIndex == 0)
        {
            /*Retry authentication*/
            [self doAuthentication];
        }
        else if (buttonIndex == 1)
        {
            /*Remove loading message*/
            [self removeLoadingView];
            /*Cancel authentication and disable local heartbeat*/
            [self disableLocalHeartbeat];
        }
    }
}

#pragma mark - Loading view

/*Show a loading view over the whole screen*/
- (void)showLoadingViewWithText:(NSString *)text
{
    /*First remove*/
    [self removeLoadingView];
    
    /*Then add new*/
    self.loadingView = [[LoadingViewController alloc] initWithNibName:@"LoadingViewController" bundle:[NSBundle mainBundle]];
    self.loadingView.view.frame = self.window.rootViewController.view.bounds;
    [self.window addSubview:self.loadingView.view];
    self.loadingView.loadingLabel.text = text;
    [self.navigationController presentViewController:self.loadingView animated:YES completion:nil];
}

/*Remove thr loading view*/
- (void)removeLoadingView
{
    if (self.loadingView != nil)
    {
        [self.loadingView.view removeFromSuperview];
        self.loadingView = nil;
    }
}

#pragma mark - Set access to control of Hue and Sphero using a BOOL

- (BOOL)setDidPresentHueView
{//This is used to check if we already had access to the Hue control view!
    /*First (re)set BOOL to NO then return YES*/
    self.didPresentHueView = NO;
    self.didPresentHueView = YES;
    return self.didPresentHueView;
}

- (BOOL)setDidPresentSpheroView
{//This is used to check if we already had access to the Sphero control view!
    /*First (re)set BOOL to NO then return YES*/
    self.didPresentSpheroView = NO;
    self.didPresentSpheroView = YES;
    return self.didPresentSpheroView;
}

@end