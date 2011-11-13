//
//  OptionsViewController.m
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 11/12/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import "OptionsViewController.h"
#import "InteractionLayer.h"

@interface OptionsViewController()
@property (nonatomic,retain) NSMutableDictionary *values;
@property (nonatomic,retain) UISwitch *markersSwitch;
@property (nonatomic,retain) UISwitch *particlesSwitch;
@property (nonatomic,retain) UISwitch *labelsSwitch;
@end

@implementation OptionsViewController

@synthesize values;
@synthesize delegate;
@synthesize markersSwitch;
@synthesize particlesSwitch;
@synthesize labelsSwitch;

+ (OptionsViewController *)loadFromNib
{
    OptionsViewController *viewC = [[[OptionsViewController alloc] initWithNibName:@"OptionsView" bundle:nil] autorelease];
    
    return viewC;
}

// We're keeping the parameter values global, basically
NSMutableDictionary *valueDict = nil;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Only one shared value dictionary
        if (!valueDict)
        {
            valueDict = [[NSMutableDictionary dictionary] retain];
            // Start with all the features off
            [valueDict setObject:[NSNumber numberWithBool:NO] forKey:kWGMarkerSwitch];
            [valueDict setObject:[NSNumber numberWithBool:NO] forKey:kWGParticleSwitch];
            [valueDict setObject:[NSNumber numberWithBool:NO] forKey:kWGLabelSwitch];
        }
        self.values = valueDict;

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.markersSwitch.on = [[values objectForKey:kWGMarkerSwitch] boolValue];
    self.particlesSwitch.on = [[values objectForKey:kWGParticleSwitch] boolValue];
    self.labelsSwitch.on = [[values objectForKey:kWGLabelSwitch] boolValue];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)markersAction:(UISwitch *)sender
{
    [values setObject:[NSNumber numberWithBool:sender.on] forKey:kWGMarkerSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWGMarkerSwitch object:[NSNumber numberWithBool:sender.on]];
}

- (IBAction)particlesAction:(UISwitch *)sender;
{
    [values setObject:[NSNumber numberWithBool:sender.on] forKey:kWGParticleSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWGParticleSwitch object:[NSNumber numberWithBool:sender.on]];
}

- (IBAction)labelsAction:(UISwitch *)sender
{
    [values setObject:[NSNumber numberWithBool:sender.on] forKey:kWGLabelSwitch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWGLabelSwitch object:[NSNumber numberWithBool:sender.on]];
}


@end
