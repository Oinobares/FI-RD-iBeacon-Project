//
//  BeaconControl.h
//  iBeacon
//
//  Created by Yvan Siggen on 3/19/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface BeaconControl : NSObject

/*Properties/methods for Monitoring a Beacon*/
@property CLLocationManager *locationManager;
@property CLBeaconRegion *beaconRegion;
@property CLRegion *region;
- (void)initLocationManager;

@end