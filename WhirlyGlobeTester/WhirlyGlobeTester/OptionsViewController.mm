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
@property (nonatomic,retain) UISegmentedControl *countryControl;
@property (nonatomic,retain) UISegmentedControl *markersControl;
@property (nonatomic,retain) UISwitch *particlesSwitch;
@property (nonatomic,retain) UISegmentedControl *loftedControl;    
@property (nonatomic,retain) UISwitch *gridSwitch;
@property (nonatomic,retain) UISwitch *statsSwitch;
@property (nonatomic,retain) NSMutableDictionary *values;
@end

@implementation OptionsViewController

@synthesize countryControl;
@synthesize markersControl;
@synthesize particlesSwitch;
@synthesize loftedControl;
@synthesize gridSwitch;
@synthesize statsSwitch;
@synthesize values;
@synthesize delegate;

+ (OptionsViewController *)loadFromNib
{
    OptionsViewController *viewC = [[[OptionsViewController alloc] initWithNibName:@"OptionsView" bundle:nil] autorelease];
    
    return viewC;
}

// We're keeping the parameter values global, basically
NSMutableDictionary *valueDict = nil;

+ (NSDictionary *)fetchValuesDict
{
    // Only one shared value dictionary
    if (!valueDict)
    {
        valueDict = [[NSMutableDictionary dictionary] retain];
        // Start with all the features off
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGCountryControl];
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGMarkerControl];
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGParticleControl];
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGLoftedControl];
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGGridControl];
        [valueDict setObject:[NSNumber numberWithInt:0] forKey:kWGStatsControl];
    }

    return [NSDictionary dictionaryWithDictionary:valueDict];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.values = valueDict;

    }
    return self;
}

- (void)clear
{
    self.countryControl = nil;
    self.markersControl = nil;
    self.particlesSwitch = nil;
    self.loftedControl = nil;
    self.gridSwitch = nil;
    self.statsSwitch = nil;
}

- (void)dealloc
{
    [self clear];
    self.values = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self clear];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.countryControl.selectedSegmentIndex = [[values objectForKey:kWGCountryControl] intValue];
    self.markersControl.selectedSegmentIndex = [[values objectForKey:kWGMarkerControl] intValue];
    self.particlesSwitch.on = [[values objectForKey:kWGParticleControl] boolValue];
    self.loftedControl.selectedSegmentIndex = [[values objectForKey:kWGLoftedControl] intValue];
    self.gridSwitch.on = [[values objectForKey:kWGGridControl] boolValue];
    self.statsSwitch.on = [[values objectForKey:kWGStatsControl] boolValue];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// One of the controls changes, update the dictionary and send out a notification
- (IBAction)valueChangeAction:(id)sender
{
    [values setObject:[NSNumber numberWithInt:self.countryControl.selectedSegmentIndex] forKey:kWGCountryControl];
    [values setObject:[NSNumber numberWithInt:self.markersControl.selectedSegmentIndex] forKey:kWGMarkerControl];
    [values setObject:[NSNumber numberWithBool:self.particlesSwitch.on] forKey:kWGParticleControl];
    [values setObject:[NSNumber numberWithInt:self.loftedControl.selectedSegmentIndex] forKey:kWGLoftedControl];
    [values setObject:[NSNumber numberWithBool:self.gridSwitch.on] forKey:kWGGridControl];
    [values setObject:[NSNumber numberWithBool:self.statsSwitch.on] forKey:kWGStatsControl];

    [[NSNotificationCenter defaultCenter] postNotificationName:kWGControlChange object:self.values];
}

@end
