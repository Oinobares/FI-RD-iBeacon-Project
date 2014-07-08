//
//  DefaultBeacons.m
//  iBeacon
//
//  Created by Yvan Siggen on 3/20/14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "DefaultBeacons.h"

@implementation DefaultBeacons

/*Init default Beacon UUID*/
- (id)init
{
    self = [super init];
    if (self) {
        /*If you would like to support more than one UUID, add the NSArray from the header file and make a list of objects with the UUIDs like this :*/
//        _supportedProximityUUIDs = [[[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"],
//                                    [[NSUUID alloc] initWithUUIDString:@"replace with valid UUID"]];
        _supportedProximityUUID = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
        _defaultPower = @-59;
    }
    return self;
}

/*Singleton*/
+ (DefaultBeacons *)sharedDefaultBeacons
{
    /*Init sharedObject as nil*/
    static id sharedDefaultBeacons = nil;
    static dispatch_once_t onceToken;
    /*Execute a block object only once for the lifetime of the app*/
    dispatch_once(&onceToken, ^{
        sharedDefaultBeacons = [[self alloc] init];
    });
    /*Return the same object each time*/
    return sharedDefaultBeacons;
}

@end