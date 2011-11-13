//
//  BigButtonViewController.m
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BigButtonViewController.h"

@implementation BigButtonViewController

@synthesize delegate;

+ (BigButtonViewController *)loadFromNib
{
    BigButtonViewController *viewC = [[[BigButtonViewController alloc] initWithNibName:@"BigButtonView" bundle:nil] autorelease];
    
    return viewC;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Big Button";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// Button was pressed.  Notify the delegate
- (IBAction)buttonPress:(id)sender
{
    [delegate bigButtonPushed:self];
}

@end
