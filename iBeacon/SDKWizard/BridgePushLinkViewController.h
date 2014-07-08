//
//  BridgePushLinkViewController.h
//  iBeacon
//
//  Created by ySiggen on 02.04.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHError;
@class PHHueSDK;

/*Delegate protocol for this view controller*/
@protocol BridgePushLinkViewControllerDelegate <NSObject>

@required

/*Method invoked when pushlinking is successful*/
- (void)pushlinkSuccess;

/*Method invoked when pushlinking failed*/
- (void)pushlinkFailed:(PHError *)error;

@end

/*This view controller allows pushlinking (authentication) of a local bridge*/
@interface BridgePushLinkViewController : UIViewController

@property (nonatomic, unsafe_unretained) id<BridgePushLinkViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) PHHueSDK *phHueSDK;

/** Creates a new instance of this view controller. @param hueSdk is the HueSDK instance to use. @param delegate is the delegate to inform when the pushlinking is done*/
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil hueSDK:(PHHueSDK *)hueSdk delegate:(id<BridgePushLinkViewControllerDelegate>) delegate;

/*Start the pushlinking process*/
- (void)startPushLinking;

@end
