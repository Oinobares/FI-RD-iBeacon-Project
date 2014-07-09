//
//  SpheroByAccelerometerViewController.m
//  FI-Beacon
//
//  Created by Yvan Siggen on 06.06.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "SpheroByAccelerometerViewController.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"
#import <CoreMotion/CMAccelerometer.h>
/*Define new update interval for accelerometer in seconds*/
#define updateInterval (0.4f)


@interface SpheroByAccelerometerViewController ()

/*Accelerometer properties*/
@property CMMotionManager *motionManager;
@property CMAccelerometerData *returnedData;
@property NSOperationQueue *theQueue;
@property float accelerometerX;
@property float accelerometerY;

/*Sphero connection status label*/
@property (strong, nonatomic) IBOutlet UILabel *connectionLabel;


@end

@implementation SpheroByAccelerometerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Initialize Accelerometer*/
    self.theQueue = [[NSOperationQueue alloc] init];
    self.returnedData = [[CMAccelerometerData alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = updateInterval;
    
    /*Start accelerometer data update*/
    [self.motionManager startAccelerometerUpdatesToQueue:self.theQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error){
        self.returnedData = self.motionManager.accelerometerData;
        self.accelerometerX = self.returnedData.acceleration.x;
        self.accelerometerY = self.returnedData.acceleration.y;
        NSLog(@"x: %f // y: %f ACCEL UPDATE", self.accelerometerX, self.accelerometerY);
    }];

    /*Register for application lifecycle notifications so we know when to connect/disconnect from the Sphero*/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    /*Set Sphero state and background color (for the view)*/
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
    /*Stop accelerometer*/
    [self.motionManager stopAccelerometerUpdates];
    /*Closing connection to the Sphero when entering leaving this view*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
    robotOnline = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)appDidBecomeActive:(NSNotification *)notification
{
    /*Trying to connect to the Sphero after the App became active (after getting out of background)*/
    [self setupRobotConnection];
    /*Restart the accelerometer service*/
    [self.motionManager startAccelerometerUpdatesToQueue:self.theQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error){
        self.returnedData = self.motionManager.accelerometerData;
        self.accelerometerX = self.returnedData.acceleration.x;
        self.accelerometerY = self.returnedData.acceleration.y;
    }];
} 

- (void)appWillResignActive:(NSNotification *)notification
{
    /*Stop accelerometer*/
    [self.motionManager stopAccelerometerUpdates];
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
    
    if (robotOnline) {
        /*Tell Sphero to toggle its LED and start controlling it with the accelerometer*/
        [self toggleLED];
        [self controlByAccelerometer];
    }
    
    // Hide No Sphero Connected View
    if( noSpheroViewShowing ) {
        [noSpheroView dismissModalLayerViewControllerAnimated:YES];
        noSpheroViewShowing = NO;
    }
}

/*Setup the connection to the Sphero*/
- (void)setupRobotConnection
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGainControl:) name:RKRobotDidGainControlNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOffline) name:RKDeviceConnectionOfflineNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOffline) name:RKRobotDidLossControlNotification object:nil];
    
    /*Try to control the connected Sphero in order to get a notification if one is connected*/
    
    robotInitialized = NO;
    robotOnline = NO;
    self.view.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
    
    
    /*Intialize the Sphero*/
    [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    self.connectionLabel.text = @"En connexion...";
    self.connectionLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    
    /*Give the device a second to connect*/
    [self performSelector:@selector(showNoSpheroConnectedView) withObject:nil afterDelay:1.0];
    
    robotInitialized = YES;
}

- (void)handleDidGainControl:(NSNotification *)notification
{
    if (!robotInitialized)
    {
        return;
    }
    [[RKRobotProvider sharedRobotProvider] openRobotConnection];
}

- (void)handleRobotOffline
{
    if(robotOnline)
    {
        robotOnline = NO;
        self.connectionLabel.text = @"Déconnecté";
        [self showNoSpheroConnectedView];
    }
}

- (void)showNoSpheroConnectedView
{
    if (robotOnline) {
        return;
    }
    //RobotUIKit resources like images and nib files stored in an external bundle and the path must be specified
    NSString* rootpath = [[NSBundle mainBundle] bundlePath];
    NSString* ruirespath = [NSBundle pathForResource:@"RobotUIKit" ofType:@"bundle" inDirectory:rootpath];
    NSBundle* ruiBundle = [NSBundle bundleWithPath:ruirespath];
    
    NSString* nibName;
    // Set up for iPhone/ipod
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // Change if your app is portrait
        nibName = @"RUINoSpheroConnectedViewController_Portrait";
        //nibName = @"RUINoSpheroConnectedViewController_Landscape";
    }
    
    noSpheroView = [[RUINoSpheroConnectedViewController alloc]
                    initWithNibName:nibName
                    bundle:ruiBundle];
    [self presentModalLayerViewController:noSpheroView animated:YES];
    noSpheroViewShowing = YES;
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

/*Sphero control commands according to accelerometer data*/
- (void)controlByAccelerometer
{
    /*Get a copy of the accelerometer data*/
    float x = self.accelerometerX;
    float y = self.accelerometerY;
    NSLog(@"x : %f // y: %f CONTROL", x, y);//TEST
    
    /*
     *The control was calculated as follows :
     * - the speed depends on the y (from -1.0 to 1.0) data retrieved from the accelerometer
     * - the turn angle depends on the x data (from -1.0 to 1.0)
     * - the speed for the Sphero goes from 0.0 to 1.0
     * - the turn angles for the Sphero go from 0.0 to 90.0 for right and 270.0 to 0.0 (or 360.0, not used here) for left. Those angles are for going forward!
     *In the end, we have therefore a y=1 to speed=1 ratio. And a x=1 to angle=90° ratio, furthermore x=-1 is for angle=270°, x=0 is for angle=0°.
     *
     *The same process goes for going backwards, except that the speed of the Sphero is calibrated according to the y data of the accelerometer from 0.0 to -1.0.
     *And the angles go from 90° to 180° for backwards right and from 270° to 180° backwards left.
     */
    
    /*Forward*/
    if (y >= 0.3 && y < 0.5 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND FORWARD! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:0.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD VELOCITY 0.4";
    }
    else if (y >= 0.5 && y < 0.7 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND FORWARD! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:0.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD VELOCITY 0.6";
    }
    else if (y >= 0.7 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND FORWARD! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:0.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD VELOCITY 0.8";
    }
    /*Forward Right (30°)*/
    else if (y >= 0.3 && y < 0.5 && x > 0.165 && x < 0.495){
        NSLog(@"SEND FORWARD 30°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:30.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 30° VEL 0.4";
    }
    else if (y >= 0.5 && y < 0.7 && x > 0.165 && x < 0.494){
        NSLog(@"SEND FORWARD 30°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:30.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD 30° VEL 0.6";
    }
    else if (y >= 0.7 && x > 0.165 && x < 0.494){
        NSLog(@"SEND FORWARD 30°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:30.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD 30° VEL 0.8";
    }
    /*Forward Right (60°)*/
    else if (y >= 0.3 && y < 0.5 && x > 0.495 && x < 0.624){
        NSLog(@"SEND FORWARD 60°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:60.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 60° VEL 0.4";
    }
    else if (y >= 0.5 && y < 0.7 && x > 0.495 && x < 0.624){
        NSLog(@"SEND FORWARD 60°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:60.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD 60° VEL 0.6";
    }
    else if (y >= 0.7 && x > 0.495 && x < 0.624){
        NSLog(@"SEND FORWARD 60°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:60.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD 60° VEL 0.8";
    }
    /*Forward Right (90°)*/
    else if (y >= 0.3 && y < 0.5 && x > 0.625){
        NSLog(@"SEND FORWARD 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 90°";
    }
    else if (y >= 0.5 && y < 0.7 && x > 0.625){
        NSLog(@"SEND FORWARD 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 90°";
    }
    else if (y >= 0.7 && x > 0.625){
        NSLog(@"SEND FORWARD 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 90°";
    }
    /*Forward Left (330°)*/
    else if (y >= 0.3 && y < 0.5 && x > -0.494 && x < -0.166){
        NSLog(@"SEND FORWARD 330°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:330.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 330°";
    }
    else if (y >= 0.5 && y < 0.7 && x > -0.494 && x < -0.166){
        NSLog(@"SEND FORWARD 330°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:330.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD 330°";
    }
    else if (y >= 0.7 && x > -0.494 && x < -0.166){
        NSLog(@"SEND FORWARD 330°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:330.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD 330°";
    }
    /*Forward Left (300°)*/
    else if (y >= 0.3 && y < 0.5 && x > -0.624 && x < -0.495){
        NSLog(@"SEND FORWARD 300°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:300.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 300°";
    }
    else if (y >= 0.5 && y < 0.7 && x > -0.624 && x < -0.495){
        NSLog(@"SEND FORWARD 300°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:300.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD 300°";
    }
    else if (y >= 0.7 && x > -0.624 && x < -0.495){
        NSLog(@"SEND FORWARD 300°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:300.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD 300°";
    }
    /*Forward Left (270°)*/
    else if (y >= 0.3 && y < 0.5 && x < -0.625){
        NSLog(@"SEND FORWARD 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.4];
        self.connectionLabel.text = @"FORWARD 270°";
    }
    else if (y >= 0.5 && y < 0.7 && x < -0.625){
        NSLog(@"SEND FORWARD 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.6];
        self.connectionLabel.text = @"FORWARD 270°";
    }
    else if (y >= 0.7 && x < -0.625){
        NSLog(@"SEND FORWARD 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.8];
        self.connectionLabel.text = @"FORWARD 270°";
    }
    /*Backwards*/
    else if (y < -0.3 && y >= -0.5 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND BACKWARDS! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:180.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS VELOCITY 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND BACKWARDS! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:180.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS VELOCITY 0.6";
    }
    else if (y < -0.7 && x > -0.165 && x <= 0.165){
        NSLog(@"SEND BACKWARDS! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:180.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS VELOCITY 0.8";
    }
    /*Backwards right (90°)*/
    else if (y < -0.3 && y >= -0.5 && x > 0.625){
        NSLog(@"SEND BACKWARDS 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 90° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > 0.625){
        NSLog(@"SEND BACKWARDS 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 90° VEL 0.6";
    }
    else if (y < -0.7 && x > 0.625){
        NSLog(@"SEND BACKWARDS 90°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:90.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 90° VEL 0.8";
    }
    /*Backwards right (120°)*/
    else if (y < -0.3 && y >= -0.5 && x > 0.495 && x < 0.624){
        NSLog(@"SEND BACKWARDS 120°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:120.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 120° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > 0.495 && x < 0.624){
        NSLog(@"SEND BACKWARDS 120°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:120.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 120° VEL 0.6";
    }
    else if (y < -0.7 && x > 0.495 && x < 0.624){
        NSLog(@"SEND BACKWARDS 120°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:120.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 120° VEL 0.8";
    }
    /*Backwards right (150°)*/
    else if (y < -0.3 && y >= -0.5 && x > 0.165 && x < 0.495){
        NSLog(@"SEND BACKWARDS 150°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:150.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 150° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > 0.165 && x < 0.494){
        NSLog(@"SEND BACKWARDS 150°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:150.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 150° VEL 0.6";
    }
    else if (y < -0.7 && x > 0.165 && x < 0.494){
        NSLog(@"SEND BACKWARDS 150°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:150.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 150° VEL 0.8";
    }
    /*Backwards left (270°)*/
    else if (y < -0.3 && y >= -0.5 && x < -0.625){
        NSLog(@"SEND BACKWARDS 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 270° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x < -0.625){
        NSLog(@"SEND BACKWARDS 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 270° VEL 0.6";
    }
    else if (y < -0.7 && x < -0.625){
        NSLog(@"SEND BACKWARDS 270°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:270.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 270° VEL 0.8";
    }
    /*Backwards left (240°)*/
    else if (y < -0.3 && y >= -0.5 && x > -0.624 && x < -0.495){
        NSLog(@"SEND BACKWARDS 240°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:240.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 240° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > -0.624 && x < -0.495){
        NSLog(@"SEND BACKWARDS 240°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:240.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 240° VEL 0.6";
    }
    else if (y < -0.7 && x > -0.624 && x < -0.495){
        NSLog(@"SEND BACKWARDS 240°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:240.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 240° VEL 0.8";
    }
    /*Backwards left (210°)*/
    else if (y < -0.3 && y >= -0.5 && x > -0.494 && x < -0.166){
        NSLog(@"SEND BACKWARDS 210°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:210.0 velocity:0.4];
        self.connectionLabel.text = @"BACKWARDS 210° VEL 0.4";
    }
    else if (y < -0.5 && y >= -0.7 && x > -0.494 && x < -0.166){
        NSLog(@"SEND BACKWARDS 210°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:210.0 velocity:0.6];
        self.connectionLabel.text = @"BACKWARDS 210° VEL 0.6";
    }
    else if (y < -0.7 && x > -0.494 && x < -0.166){
        NSLog(@"SEND BACKWARDS 210°! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendCommandWithHeading:210.0 velocity:0.8];
        self.connectionLabel.text = @"BACKWARDS 210° VEL 0.8";
    }
    /*Stop Sphero*/
    else{
        NSLog(@"SEND STOP! x: %f // y: %f", self.accelerometerX, self.accelerometerY);
        [RKRollCommand sendStop];
        self.connectionLabel.text = @"STOP";
    }

    /*Keep controlling the Sphero with the accelerometer if we are still connected to it.*/
    if (robotOnline){
        NSLog(@"PERFORM SELECTOR!");
        [self performSelector:@selector(controlByAccelerometer) withObject:nil afterDelay:0.5];
    }
}

@end
