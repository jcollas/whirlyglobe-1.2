//
//  RootViewController.m
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import "RootViewController.h"
#import "DetailViewController.h"

#define TABLE_ROWS 10


@implementation RootViewController


@synthesize detailViewController;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(310.0, self.tableView.rowHeight*TABLE_ROWS);
    //self.contentSizeForViewInPopover = CGSizeMake(320.0, 300.0);
    //    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0); //original length size

}


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)selectFirstRow
{
	if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
		[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
	}
}


#pragma mark -
#pragma mark Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    // Return the number of sections.
    return 1;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
    // Two sections, one for each detail view controller.
    return TABLE_ROWS;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"CellIdentifier";
    
/*
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Configure the cell.
    cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    return cell;
 */
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    switch (indexPath.row)
    {
        case 0: 
        {
            cell.textLabel.text = @"Data 1";    
            break;
        }
        case 1: 
        {
            cell.textLabel.text = @"Data 2";    
            break;
        }
        case 2: 
        {
            cell.textLabel.text = @"Data 3";    
            break;
        }
        case 3: 
        {
            cell.textLabel.text = @"Data 4";    
            break;
        }
        case 4: 
        {
            cell.textLabel.text = @"Data 5";    
            break;
        }
        case 5: 
        {
            cell.textLabel.text = @"Data 6";    
            break;
        }
        case 6: 
        {
            cell.textLabel.text = @"Data 7";    
            break;
        }
        case 7: 
        {
            cell.textLabel.text = @"Data 8";    
            break;
        }
        case 8: 
        {
            cell.textLabel.text = @"Data 9";    
            break;
        }
        case 9: 
        {
            cell.textLabel.text = @"Data 10";    
            break;
        }

    }
    return cell;
}


#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// When a row is selected, set the detail view controller's detail item to the item associated with the selected row.
//    detailViewController.detailItem = [NSString stringWithFormat:@"Globe View %d", indexPath.row];

    // Note: Notify the detail view of the change in variable
    
    /*
    // Create and configure a new detail view controller appropriate for the selection.
    // Save this example for later... TBD - we shall see how this will work.
     
    NSUInteger row = indexPath.row;
    
    UIViewController <SubstitutableDetailViewController> *detailViewController = nil;
    
    if (row == 0) {
        FirstDetailViewController *newDetailViewController = [[FirstDetailViewController alloc] initWithNibName:@"FirstDetailView" bundle:nil];
        detailViewController = newDetailViewController;
    }
    
    if (row >= 1) {
        SecondDetailViewController *newDetailViewController = [[SecondDetailViewController alloc] initWithNibName:@"SecondDetailView" bundle:nil];
        NSLog(@"Chapter Number %d", row);
        
        newDetailViewController.chapterNumber = row - 1;
        
        detailViewController = newDetailViewController;
    }
    
    // Update the split view controller's view controllers array.
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, detailViewController, nil];
    splitViewController.viewControllers = viewControllers;
    [viewControllers release];
    
    // Dismiss the popover if it's present.
    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }
    
    // Configure the new view controller's popover button (after the view has been displayed and its toolbar/navigation bar has been created).
    if (rootPopoverButtonItem != nil) {
        [detailViewController showRootPopoverButtonItem:self.rootPopoverButtonItem];
    }
    
    [detailViewController release];
     */

}


#pragma mark -
#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { 
    if((indexPath.row + (indexPath.section % 2))% 2 == 0)  
        cell.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    else{
        cell.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];

    }
        cell.textLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];

} 

#pragma mark -
#pragma mark Memory management


- (void)dealloc
{
    [detailViewController release];
    [super dealloc];
}


@end
