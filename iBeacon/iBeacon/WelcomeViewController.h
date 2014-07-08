//
//  WelcomeViewController.h
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "BridgeSelectionViewController.h"

@interface WelcomeViewController : UIViewController

/*Label for the Region Detection in the Toolbar (inside/outside Region 1)*/
@property (weak, nonatomic) IBOutlet UIBarButtonItem *regionButtonLabel;

/*Unwind Segue*/
- (IBAction)unwindToWelcome:(UIStoryboardSegue *)segue;

@end
