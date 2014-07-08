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
    
    /*Init a beacon region.
     *You can specifiy a specific region by changing the major and minor.
     *The UUID is set in DefaultBeacons.m/.h
     */
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[DefaultBeacons sharedDefaultBeacons].supportedProximityUUID major:1705 minor:4 identifier:@"Zone1"];
    
    /*Start monitoring for the chosen region*/
    [self.locationManager startMonitoringForRegion:_beaconRegion];
}

- (void)startMonitoringBeaconRegion
{
    [self.locationManager startMonitoringForRegion:_beaconRegion];
}

- (void)stopMonitoringBeaconRegion
{
    [self.locationManager stopMonitoringForRegion:_beaconRegion];
}

@end