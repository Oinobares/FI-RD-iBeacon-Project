//
//  AppDelegate.h
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//
#import "BridgePushLinkViewController.h"
#import "BridgeSelectionViewController.h"
#import <HueSDK_iOS/HueSDK.h>

@import CoreLocation;

@class PHHueSDK;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, BridgePushLinkViewControllerDelegate, BridgeSelectionViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

/*Bool checking if we have currently access to Hue and Sphero system*/
@property (nonatomic) BOOL didPresentHueView;
@property (nonatomic) BOOL didPresentSpheroView;
- (BOOL)setDidPresentHueView;
- (BOOL)setDidPresentSpheroView;

#pragma mark - iBeacon

/*Bool inRegion to detect if we are in Region 1 on Welcome View Controller*/
@property BOOL inRegion;

@property CLLocationManager *locationManager;
@property CLRegion *region;

#pragma mark - HueSDK

@property (strong, nonatomic) PHHueSDK *phHueSDK;

/*Start local heartbeat*/
- (void)enableLocalHeartbeat;
/*Stop local heartbeat*/
- (void)disableLocalHeartbeat;
/*Start searching for a bridge*/
- (void)searchForBridgeLocal;

@end
