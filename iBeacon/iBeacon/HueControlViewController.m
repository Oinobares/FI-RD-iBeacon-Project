//
//  HueControlViewController.m
//  iBeacon
//
//  Created by ySiggen on 31.03.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "HueControlViewController.h"
#import "BridgeSelectionViewController.h"
#import "AppDelegate.h"

#import <HueSDK_iOS/HueSDK.h>
#define MAX_HUE 65535

@interface HueControlViewController ()

@property BridgeSelectionViewController *bridgeSelectionViewController;

@property AppDelegate *appDelegate;

@property (nonatomic, weak) IBOutlet UILabel *bridgeMacLabel;
@property (nonatomic, weak) IBOutlet UILabel *bridgeIpLabel;
@property (nonatomic, weak) IBOutlet UILabel *bridgeLastHeartbeatLabel;
@property (nonatomic, weak) IBOutlet UIButton *randomLightsButton;
@property (weak, nonatomic) IBOutlet UISwitch *onOffButton;

@end

@implementation HueControlViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PHNotificationManager *notificationManager = [PHNotificationManager defaultManager];
    /*Register for the local heartbeat notifications*/
    [notificationManager registerObject:self withSelector:@selector(localConnection) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [notificationManager registerObject:self withSelector:@selector(noLocalConnection) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    
    /*Set the labels and button status*/
    [self noLocalConnection];
    
    /***************************************************
     The local heartbeat is a regular timer event in the SDK. Once enabled the SDK regular collects the current state of resources managed
     by the bridge into the Bridge Resources Cache
     *****************************************************/
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.appDelegate enableLocalHeartbeat];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)localConnection
{
    [self loadConnectedBridgeValues];
}

- (void)noLocalConnection
{
    /*Set labels & button state when no local connection*/
    self.bridgeLastHeartbeatLabel.text = @"Pas connecté";
    [self.bridgeLastHeartbeatLabel setEnabled:NO];
    self.bridgeIpLabel.text = @"Pas connecté";
    [self.bridgeIpLabel setEnabled:NO];
    self.bridgeMacLabel.text = @"Pas connecté";
    [self.bridgeMacLabel setEnabled:NO];
    
    [self.randomLightsButton setEnabled:NO];
    [self.onOffButton setEnabled:NO];
}

- (void)loadConnectedBridgeValues
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    
    /*Check if we have connected to a bridge before*/
    if (cache != nil && cache.bridgeConfiguration != nil && cache.bridgeConfiguration.ipaddress != nil)
    {
        /*Set ip address of the bridge*/
        self.bridgeIpLabel.text = cache.bridgeConfiguration.ipaddress;
        /*Set mac address of the bridge*/
        self.bridgeMacLabel.text = cache.bridgeConfiguration.mac;
        
        /*Check if we are connected to the bridhe right now*/
        if (self.appDelegate.phHueSDK.localConnected)
        {
            /*Show current time as last successful heartbeat time when we are connected to a bridge*/
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            
            self.bridgeLastHeartbeatLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]];
            
            /*Enable buttons*/
            [self.randomLightsButton setEnabled:YES];
            [self.onOffButton setEnabled:YES];
        }
        else
        {
            self.bridgeLastHeartbeatLabel.text = @"En attente...";
            
            /*Disable buttons*/
            [self.randomLightsButton setEnabled:NO];
            [self.onOffButton setEnabled:NO];
        }
    }
}

- (IBAction)selectOtherBridge:(id)sender
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.appDelegate searchForBridgeLocal];
}

- (IBAction)randomizeColoursOfConectLights:(id)sender
{
    /*Disable the button*/
    [self.randomLightsButton setEnabled:NO];
    
    /*Get the bridge resources cache*/
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    id<PHBridgeSendAPI> bridgeSendAPI = [[[PHOverallFactory alloc] init] bridgeSendAPI];
    
    for (PHLight *light in cache.lights.allValues)
    {
        PHLightState *lightState = [[PHLightState alloc] init];
        
        /*Chose a random color*/
        [lightState setHue:[NSNumber numberWithInt:arc4random() % MAX_HUE]];
        /*Set brightness*/
        [lightState setBrightness:[NSNumber numberWithInt:100]];
        /*Set saturation*/	
        [lightState setSaturation:[NSNumber numberWithInt:254]];
        
        /*Send lightstate to light*/
        [bridgeSendAPI updateLightStateForId:light.identifier withLighState:lightState completionHandler:^(NSArray *errors){
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@", message);
            }
            /*Enable the button*/
            [self.randomLightsButton setEnabled:YES];
        }];
    }
}

- (IBAction)setOnOffOfConnectedLights:(id)sender
{
    /*Disable the button*/
    [self.onOffButton setEnabled:NO];
    
    /*Read the bridge resources cache*/
    PHBridgeResourcesCache *cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    id<PHBridgeSendAPI> bridgSendAPI = [[[PHOverallFactory alloc] init] bridgeSendAPI];
    
    for (PHLight *light in cache.lights.allValues)
    {
        PHLightState *lightState = [[PHLightState alloc] init];
        /*Set lightstat to On or Off depending on the state of the switch button*/
        if (self.onOffButton.on == YES) {
            [lightState setOnBool:YES];
        }
        else if (self.onOffButton.on == NO)
        {
            [lightState setOnBool:NO];
        }
        /*Send lightstate*/
        [bridgSendAPI updateLightStateForId:light.identifier withLighState:lightState completionHandler:^(NSArray *errors){
            if (errors != nil) {
                NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Errors", @""), errors != nil ? errors : NSLocalizedString(@"none", @"")];
                NSLog(@"Response: %@", message);
            }
            /*Enable button*/
            [self.onOffButton setEnabled:YES];
        }];
    }
}

- (IBAction)findNewBridgeButtonAction:(id)sender
{
    /*Search for bridge*/
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.appDelegate searchForBridgeLocal];
}

@end
