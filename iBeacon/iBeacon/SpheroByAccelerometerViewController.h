//
//  SpheroByAccelerometerViewController.h
//  FI-Beacon
//
//  Created by Yvan Siggen on 06.06.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>

@interface SpheroByAccelerometerViewController : UIViewController {
    BOOL robotOnline;
    BOOL robotInitialized;
    BOOL ledON;
    
    BOOL noSpheroViewShowing;
    RUINoSpheroConnectedViewController* noSpheroView;
    
    /*Calibration gesture controls*/
    RUICalibrateButtonGestureHandler *calibrateAboveHandler;
    RUICalibrateGestureHandler *calibrateTwoFingerHandler;
    IBOutlet UIButton *calibrateAboveButton;
}

/*The 2 methods below are necessary to connect to a Sphero and maintain the connection*/
- (void)setupRobotConnection;
- (void)handleRobotOnline;

@end
