//
//  DefaultBeacons.h
//  iBeacon
//
//  Created by Yvan Siggen on 3/20/14.
//  Copyright (c) 2014 *. All rights reserved.
//

@interface DefaultBeacons : NSObject

+ (DefaultBeacons *)sharedDefaultBeacons;

/*Create an array if more than one Beacon*/
//@property (nonatomic, copy, readonly) NSArray *supportedProximityUUIDs;
@property (nonatomic, copy, readonly) NSUUID *supportedProximityUUID;
@property (nonatomic, copy, readonly) NSNumber *defaultPower;

@end
