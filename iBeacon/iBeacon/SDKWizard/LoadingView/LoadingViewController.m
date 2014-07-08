//
//  LoadingViewController.m
//  iBeacon
//
//  Created by ySiggen on 02.04.14.
//  Copyright (c) 2014 *. All rights reserved.
//

#import "LoadingViewController.h"

@interface LoadingViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation LoadingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        /*Make it stay fullscreen*/
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /*Animate activity indicator animation*/
    [self.activityIndicator startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    /*Stop activity indicatore animation*/
    [self.activityIndicator stopAnimating];
}

/*Deprecated??*/
- (void)viewDidUnload
{
    [self setLoadingLabel:nil];
    [super viewDidUnload];
}

@end
