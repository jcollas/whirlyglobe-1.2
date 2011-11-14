//
//  OptionsViewController.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 11/12/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OptionsViewController;

// Fill this in to get results from the options controller
@protocol OptionsControllerDelegate <NSObject>

@end

/** Options View Controller
    Allows the user to turn on and off various displayed features.
 */
@interface OptionsViewController : UIViewController
{
    NSObject<OptionsControllerDelegate> *delegate;
    NSMutableDictionary *values;  // Used to store switch values
    IBOutlet UISegmentedControl *countryControl;
    IBOutlet UISegmentedControl *markersControl;
    IBOutlet UISwitch *particlesSwitch;
    IBOutlet UISegmentedControl *loftedControl;    
    IBOutlet UISwitch *gridSwitch;
    IBOutlet UISwitch *statsSwitch;
}

@property (nonatomic,assign) NSObject<OptionsControllerDelegate> *delegate;

// Use this to create one
+ (OptionsViewController *)loadFromNib;

// Return a copy of the current values dictionary
+ (NSDictionary *)fetchValuesDict;

// Various actions are tied to switches
- (IBAction)valueChangeAction:(id)sender;

@end
