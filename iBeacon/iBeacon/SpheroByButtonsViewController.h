//
//  SpheroByButtonsViewController.h
//  FI-Beacon
//
//  Created by Yvan Siggen on 22.05.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>

@interface SpheroByButtonsViewController : UIViewController {
    /*Sphero state booleans*/
    BOOL robotOnline;
    BOOL robotInitialized;
    BOOL ledON;
    
    UILabel *connectionLabel;
    
    /*Calibration gesture controls*/
    RUICalibrateButtonGestureHandler *calibrateAboveHandler;
    RUICalibrateGestureHandler *calibrateTwoFingerHandler;
    IBOutlet UIButton *calibrateAboveButton;
}

/*The 2 methods below are necessary to connect to a Spher and maintain the connection*/
- (void)setupRobotConnection;
- (void)handleRobotOnline;

/*connectionLabel & toggleLed are used for the "Hello World" Test which is blinking the Sphero LED!*/
@property (strong, nonatomic) IBOutlet UILabel *connectionLabel;
- (void)toggleLED;

@end
