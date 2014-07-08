//
//  WelcomeViewController.m
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AppDelegate.h"

@interface WelcomeViewController () 

@end

@implementation WelcomeViewController

- (IBAction)unwindToWelcome:(UIStoryboardSegue *)segue
{
    //Unwind Segue
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Refresh the toolbar when Region state changed*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView:) name:@"refreshView" object:nil];
}

- (void)refreshView:(NSNotification *)notification /*Change toolbar color and message according to the region state (outside or inside of Region)*/
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.inRegion == YES)
    {/*If inside region : set some green color with a message */
        self.navigationController.toolbar.barTintColor = [UIColor colorWithRed:(20/255.0) green:(209/255.0) blue:0 alpha:1];
        [self.regionButtonLabel setTintColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        [self.regionButtonLabel initWithTitle:@"Détection effectuée!" style:UIBarButtonItemStyleDone target:nil action:nil];
        self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    }
    else if (appDelegate.inRegion == NO)
    {/*If outside of region : set some red color with a message */
        self.navigationController.toolbar.barTintColor = [UIColor colorWithRed:(240/255.0) green:(51/255.0) blue:0 alpha:1];
        [self.regionButtonLabel setTintColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        [self.regionButtonLabel initWithTitle:@"Pas de détection de région!" style:UIBarButtonItemStyleDone target:nil action:nil];
        self.navigationController.toolbar.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    }
}

#pragma mark - Navigation

- (IBAction)onClick:(id)sender {/*Action "on click" that performs a segue when inside region*/
#warning UNCOMMENT THIS FOR REGION TEST TO WORK!
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    if (appDelegate.inRegion) {
        /*Segue has to go from the initial View to the other view. And NOT from the button to the other view!*/
        [self performSegueWithIdentifier:@"WelcomeToStaticDetectionTable" sender:self];
//    }
}

@end
