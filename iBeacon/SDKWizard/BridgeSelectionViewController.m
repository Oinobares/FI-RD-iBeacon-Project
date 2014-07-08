//
//  BridgeSelectionViewController.m
//  iBeacon
//
//  Created by ySiggen on 02.04.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "BridgeSelectionViewController.h"
#import "AppDelegate.h"

@interface BridgeSelectionViewController ()

@property AppDelegate *appDelegate;

@end

@implementation BridgeSelectionViewController

#warning When only one bridge found, select it automatically!! [ADD METHOD]

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil bridges:(NSDictionary *)bridges delegate:(id<BridgeSelectionViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.delegate = delegate;
        self.bridgesFound = bridges;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Set title of screen*/
    self.navigationItem.title = @"SmartBridge disponibles";
    //self.title = @"SmartBridge disponibles";
    /*Refresh button*/
    UIBarButtonItem *refreshBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                             target:self
                                             action:@selector(refreshButtonClicked:)];
    self.navigationItem.rightBarButtonItem = refreshBarButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)refreshButtonClicked:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.appDelegate searchForBridgeLocal];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bridgesFound.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    /*Sort bridges by mac address*/
    NSArray *sortedKeys = [self.bridgesFound.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    /*Get mac address and ip address of selected bridge*/
    NSString *mac = [sortedKeys objectAtIndex:indexPath.row];
    NSString *ip = [self.bridgesFound objectForKey:mac];
    
    /*Update cell*/
    cell.textLabel.text = [NSString stringWithFormat:@"Adresse Mac : %@", mac];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Adresse IP : %@", ip];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Connectez-vous à un SmartBridge en le sélectionnant.";
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*Sort bridges by mac address*/
    NSArray *sortedKeys = [self.bridgesFound.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    /*Get mac address and ip address of selected bridge*/
    NSString *mac = [sortedKeys objectAtIndex:indexPath.row];
    NSString *ip = [self.bridgesFound objectForKey:mac];
    
    /*Inform delegate*/
    [self.delegate bridgeSelectionWithIpAddress:ip andMacAddress:mac];
}

@end
