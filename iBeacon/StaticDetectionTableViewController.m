//
//  StaticDetectionTableViewController.m
//  iBeacon
//
//  Created by Yvan Siggen on 3/24/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "StaticDetectionTableViewController.h"
#import "AppDelegate.h"
#import "DefaultBeacons.h"
@import CoreLocation;

@interface StaticDetectionTableViewController () <CLLocationManagerDelegate>

@property AppDelegate *appDelegate;

/*Necessary iBeacon properties*/
@property CLLocationManager *locationManager;
@property CLBeaconRegion *beaconRegion;
@property CLBeacon *beacon;
@property CLBeacon *hueBeacon;
@property CLBeacon *spheroBeacon;

/*Detection table labels : usefull to customize them*/
@property (weak, nonatomic) IBOutlet UILabel *hueRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *hueLabel;
@property (weak, nonatomic) IBOutlet UILabel *spheroLabel;
@property (weak, nonatomic) IBOutlet UILabel *spheroRangeLabel;

@end

@implementation StaticDetectionTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Init location manager & region*/
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self initRegion];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /*Start ranging*/
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    /*Stop ranging*/
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Monitoring/Ranging

- (void)initRegion
{
    /*Init the region for the "Hue beacon"*/
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[DefaultBeacons sharedDefaultBeacons].supportedProximityUUID major:1705 identifier:@"Zone 2"];
    self.beacon = [[CLBeacon alloc] init];
    self.hueBeacon = [[CLBeacon alloc] init];
    self.spheroBeacon = [[CLBeacon alloc] init];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)beaconRegion
{
    /*Try to find Beacons that match the UUID, Major and Minor for Hue & Sphero systems*/
    for (int i = 0; i < [beacons count]; i++) {
        self.beacon = [beacons objectAtIndex:i];
        if (self.beacon.minor == [NSNumber numberWithInt:5]) {
            self.hueBeacon = self.beacon;
        }else if (self.beacon.minor == [NSNumber numberWithInt:6]){
            self.spheroBeacon = self.beacon;
        }
    }
    NSLog(@"hue: %@ // %d // %d", self.hueBeacon.proximityUUID, [self.hueBeacon.major integerValue], [self.hueBeacon.minor integerValue]);//Test
    NSLog(@"sphero: %@ // %d // %d", self.spheroBeacon.proximityUUID, [self.spheroBeacon.major integerValue], [self.spheroBeacon.minor integerValue]);//Test
    
    /*On ranging, reloads table view data*/
    [self.tableView reloadData];
    
    //TEST (logs) : ranging !
    if(self.hueBeacon.proximity == CLProximityImmediate)
    {
        NSLog(@"HUE immediate acc. %.2fm (static detection)", self.hueBeacon.accuracy);//TEST
    }
    else if (self.hueBeacon.proximity == CLProximityNear)
    {
        NSLog(@"HUE near acc. %.2fm (static detection)", self.hueBeacon.accuracy);//TEST
    }
    else if (self.hueBeacon.proximity == CLProximityFar)
    {
        NSLog(@"HUE far acc. %.2fm (static detection)", self.hueBeacon.accuracy);//TEST
    }
    if(self.spheroBeacon.proximity == CLProximityImmediate)
    {
        NSLog(@"SPHERO immediate acc. %.2fm (static detection)", self.spheroBeacon.accuracy);//TEST
    }
    else if (self.spheroBeacon.proximity == CLProximityNear)
    {
        NSLog(@"SPHERO near acc. %.2fm (static detection)", self.spheroBeacon.accuracy);//TEST
    }
    else if (self.spheroBeacon.proximity == CLProximityFar)
    {
        NSLog(@"SPHERO far acc. %.2fm (static detection)", self.spheroBeacon.accuracy);//TEST
    }
    //END Test : Ranging!
}

#pragma mark - Navigation

- (IBAction)unwindToStaticDetection:(UIStoryboardSegue *)segue
{
    //Unwind method
}

- (IBAction)onClickOnHueCell:(id)sender
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    /*Segue if in immediate proximity of Zone 2*/
    if (self.appDelegate.didPresentHueView == YES)
    {
        [self performSegueWithIdentifier:@"HueSegue" sender:self];
    }else if (self.hueBeacon.proximity == CLProximityImmediate)
    {
        [self performSegueWithIdentifier:@"HueSegue" sender:self];
        [self.appDelegate setDidPresentHueView];
    }
}

- (IBAction)onClickOnSpheroCell:(id)sender
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    /*Segue if in immediate proximity of Zone 3*/
    if (self.appDelegate.didPresentSpheroView == YES)
    {
        [self performSegueWithIdentifier:@"SpheroSegue" sender:self];
    }else if (self.spheroBeacon.proximity == CLProximityImmediate)
    {
        [self performSegueWithIdentifier:@"SpheroSegue" sender:self];
        [self.appDelegate setDidPresentSpheroView];
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        /*Set the Hue label text & color*/
        [self.hueLabel setTextColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        self.hueLabel.text = @"Hue";
        
        /*Set the Hue range label color*/
        [self.hueRangeLabel setTextColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        
         self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (self.hueBeacon.proximity == CLProximityImmediate || self.appDelegate.didPresentHueView == YES)
        {
            /*Set the cell to green when in immediate proximity or Hue control view was already presented*/
            cell.backgroundColor = [UIColor colorWithRed:0 green:(195/255.0) blue:(34/255.0) alpha:1];
            self.hueRangeLabel.text = @"Accès accordé!";
        }
        else if (self.hueBeacon.proximity == CLProximityNear)
        {
            /*Set the cell to orange when in near proximity*/
            cell.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(111/255.0) blue:0 alpha:1];
            self.hueRangeLabel.text = @"Rapprochez-vous encore!";
        }
        else if (self.hueBeacon.proximity == CLProximityFar)
        {
            /*Set the cell to red when in far proximity*/
            cell.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
            self.hueRangeLabel.text = @"Vous êtes trop loin!";
        }
        else if (self.hueBeacon.proximity == CLProximityUnknown)
        {
            /*Set the cell to red when the proximity is unknown*/
            cell.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
            self.hueRangeLabel.text = @"Etat du Beacon inconnu!";
        }
    }
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        /*Set the Sphero label text & color*/
        [self.spheroLabel setTextColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        self.spheroLabel.text = @"Sphero";
        
        /*Set the Sphero range label color*/
        [self.spheroRangeLabel setTextColor:[UIColor colorWithRed:(252/255.0) green:(252/255.0) blue:(252/255.0) alpha:1]];
        
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (self.spheroBeacon.proximity == CLProximityImmediate || self.appDelegate.didPresentSpheroView == YES)
        {
            /*Set the cell to green when in immediate proximity or Sphero control view was already presented*/
            cell.backgroundColor = [UIColor colorWithRed:0 green:(195/255.0) blue:(34/255.0) alpha:1];
            self.spheroRangeLabel.text = @"Accès accordé!";
        }
        else if (self.spheroBeacon.proximity == CLProximityNear)
        {
            /*Set the cell to orange when in near proximity*/
            cell.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(111/255.0) blue:0 alpha:1];
            self.spheroRangeLabel.text = @"Rapprochez-vous encore!";
        }
        else if (self.spheroBeacon.proximity == CLProximityFar)
        {
            /*Set the cell to red when in far proximity*/
            cell.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
            self.spheroRangeLabel.text = @"Vous êtes trop loin!";
        }
        else if (self.spheroBeacon.proximity == CLProximityUnknown)
        {
            /*Set the cell to red when the proximity is unknown*/
            cell.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(10/255.0) blue:(10/255.0) alpha:1];
            self.spheroRangeLabel.text = @"Etat du Beacon inconnu!";
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        /*If Hue Cell selected perform segue to Hue View*/
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HueCell"];
        [self onClickOnHueCell:cell];
    }
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        /*If Sphero Cell selected, perform segue to Sphero View*/
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SpheroCell"];
        [self onClickOnSpheroCell:cell];
    }
}

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{

    // Return the number of sections.
//    return 0;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{

    // Return the number of rows in the section.
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
