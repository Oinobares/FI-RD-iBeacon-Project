//
//  SpheroControlViewController.m
//  
//
//  Created by Yvan Siggen on 21.05.14.
//
//

#import "SpheroControlViewController.h"


@interface SpheroControlViewController ()

@property SpheroByAccelerometerViewController *spheroAccelerometerVC;

@end

@implementation SpheroControlViewController

- (IBAction)unwindToSpheroControl:(UIStoryboardSegue *)segue
{
    //Unwind method
}

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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

/*Segue to control Sphero by Buttons*/
- (IBAction)onClickOnByButtons:(id)sender
{
    [self performSegueWithIdentifier:@"SpheroButtons" sender:self];
}

- (IBAction)onClickOnByAccelerometer:(id)sender
{
    [self performSegueWithIdentifier:@"SpheroAccelerometer" sender:self];
}

@end
