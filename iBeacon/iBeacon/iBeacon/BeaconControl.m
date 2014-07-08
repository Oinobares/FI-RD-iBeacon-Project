//
//  BeaconControl.m
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "BeaconControl.h"
#import "DefaultBeacons.h"
@import CoreLocation;

@interface BeaconControl () <CLLocationManagerDelegate>

@end

@implementation BeaconControl

/*Initialization needed to create a region that we can monitor/range*/
- (void)initLocationManager
{
    /*A location manager provides the interface for location services (like retrieving location changes, reporting range of beacons,...)*/
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    /*Init a beacon region*/
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[DefaultBeacons sharedDefaultBeacons].supportedProximityUUID major:0 minor:1 identifier:@"Zone1"];
    
    /*Start monitoring for the chosen region*/
    [self.locationManager startMonitoringForRegion:_beaconRegion];
}

@end