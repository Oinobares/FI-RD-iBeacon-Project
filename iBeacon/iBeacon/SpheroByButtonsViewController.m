//
//  SpheroByButtonsViewController.m
//  FI-Beacon
//
//  Created by Yvan Siggen on 22.05.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "SpheroByButtonsViewController.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"

@interface SpheroByButtonsViewController ()

@end

@implementation SpheroByButtonsViewController

@synthesize connectionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /*Register for application lifecycle notifications so we know when to connect and disconnect from the robot*/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    /*Only start the blinking loop when the view loads*/
    robotOnline = NO;
    self.view.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
    
    /*Setup calibration gesture handler*/
    calibrateAboveHandler = [[RUICalibrateButtonGestureHandler alloc] initWithView:self.view button:calibrateAboveButton];
    calibrateAboveHandler.calibrationRadius = 200; //Size of calibration widget smaller
    calibrateAboveHandler.calibrationCircleLocation = RUICalibrationCircleLocationAbove; //Open the circle widget above the button
    /*Change color of the button*/
    [calibrateAboveHandler setBackgroundWithColor:[UIColor colorWithRed:0.1 green:0.5 blue:1 alpha:1]];
    [calibrateAboveHandler setForegroundWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
    
    /*Connect to Sphero*/
    [self setupRobotConnection];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    /*Closing connection to the Sphero when entering leaving this view*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
}

- (void)appDidBecomeActive:(NSNotification *)notification
{
    /*Trying to connect to the Sphero after the App became active (after getting out of background)*/
//    [self setupRobotConnection];
}

- (void)appWillResignActive:(NSNotification *)notification
{
    /*Closing connection to the Sphero when entering the backgroung*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
}

#pragma mark - Sphero Connections

- (void)handleRobotOnline
{
    /*Sphero is online, we can send commands*/
    robotOnline = YES;
    /*User connection information*/
    self.connectionLabel.text = @"Connecté";
    self.connectionLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    self.view.backgroundColor = [UIColor colorWithRed:0 green:(195/255.0) blue:(34/255.0) alpha:0.5];
    
    /*Tell Sphero to toggle its LED*/
    [self toggleLED];
    /*Tell Sphero to drive forward*/
    //[self driveForward];
}

/*Setup the connection to the Sphero*/
- (void)setupRobotConnection
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];

    /*Try to control the connected Sphero in order to get a notification if one is connected*/
    
    robotInitialized = NO;
    robotOnline = NO;
    self.view.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];

    
    /*Intialize the Sphero*/
    [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    self.connectionLabel.text = @"En connexion...";
    self.connectionLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    robotInitialized = YES;
}

#pragma mark - Sphero control functions

- (void)toggleLED
{
    /*Set the Sphero's LED to no color and then to a color*/
    if (ledON){
        ledON = NO;
        [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    }else{
        ledON = YES;
        [RKRGBLEDOutputCommand sendCommandWithRed:1.0 green:0.0 blue:0.0];
    }
    /*Continue function only if we are connected to Sphero*/
    if (robotOnline) {
        [self performSelector:@selector(toggleLED) withObject:nil afterDelay:0.5];
    }
}

- (void)stopSphero/*Stop the sphero*/
{
    [RKRollCommand sendStop];
}

- (void)driveForward/*Makes the Sphero drive slowly forward for 2 seconds and the stop.*/
{
    [RKRollCommand sendCommandWithHeading:0.0 velocity:0.1];
    [self performSelector:@selector(stopSphero) withObject:nil afterDelay:2.0];
}

#pragma mark - Sphero Button Control

- (IBAction)stopPressed:(id)sender
{
    [RKRollCommand sendStop];
}

- (IBAction)zeroPressed:(id)sender
{
    [RKRollCommand sendCommandWithHeading:0.0 velocity:0.3];
}

- (IBAction)ninetyPressed:(id)sender
{
    [RKRollCommand sendCommandWithHeading:90.0 velocity:0.3];
}


- (IBAction)hundredEightyPressed:(id)sender
{
    [RKRollCommand sendCommandWithHeading:180.0 velocity:0.3];
}

- (IBAction)twoHundredSeventyPressed:(id)sender
{
    [RKRollCommand sendCommandWithHeading:270.0 velocity:0.3];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
