//
//  BridgeSelectionViewController.h
//  iBeacon
//
//  Created by ySiggen on 02.04.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BridgeSelectionViewControllerDelegate <NSObject>

/**Informs delegate which bridge was selected*/
- (void)bridgeSelectionWithIpAddress:(NSString *)ipAddress andMacAddress:(NSString *)macAddress;

@end

@interface BridgeSelectionViewController : UIViewController

/*Delegate object*/
@property (nonatomic, unsafe_unretained) id<BridgeSelectionViewControllerDelegate> delegate;

/*Bridges shown in list*/
@property (nonatomic, strong) NSDictionary *bridgesFound;

/*Creates new instance of view controller*/
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil bridges:(NSDictionary *)bridges delegate:(id<BridgeSelectionViewControllerDelegate>)delegate;

@end
