
/*
 File: OptionsViewController.m
 Abstract: View controller that sets up the table view and serves as the table view's data source and delegate.
 Version: 2.1
 
 */

#import "OptionsViewController.h"
#import "sqlite3.h"
#import <sqlhelpers.h>


@implementation OptionsViewController

@synthesize arrayOfStrings;
@synthesize delegate;


- (void)viewDidLoad {
//    arrayOfStrings = [[NSMutableArray alloc] initWithObjects:@"iPod Touch", @"iPhone", @"iPad", @"Portable Macs", @"Desktop Macs", @"Other iPods", @"Other Apple Products", nil];
    
    arrayOfStrings = [[NSMutableArray alloc] init];
    
//  Open DB
    NSString *dbString = [[NSBundle mainBundle] pathForResource:@"une" ofType:@"sqlite3"];
    NSLog(@"dbString = %@",dbString);
    
    sqlite3 *db;
    if (sqlite3_open([dbString cStringUsingEncoding:1],&db) != SQLITE_OK)
        NSLog(@"Warning: SQLITE problem");
    
    sqlhelpers::StatementRead readStmt(db,@"select variable_name from data_sets;");
    while (readStmt.stepRow())
        [arrayOfStrings addObject:readStmt.getString()];
    [arrayOfStrings addObject:@"None"];
    NSLog(@"arrayOfStrings = %@",arrayOfStrings);
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// There is only one section.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [arrayOfStrings count];
}

#pragma mark -
#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { 
    if((indexPath.row + (indexPath.section % 2))% 2 == 0){  
        cell.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.9];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.7 green:0.8 blue:0.7 alpha:0.9];        
    }
}  


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
    static NSString *MyIdentifier = @"MyIdentifier";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	
    // If no cell is available, create a new one using the given identifier.
	if (cell == nil) {
		// Use the default cell style.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
	}
	
	// Set up the cell.
    cell.textLabel.text = [arrayOfStrings objectAtIndex:indexPath.row];
		
	return cell;
}

/*
 To conform to Human Interface Guildelines, since selecting a row would have no effect (such as navigation), make sure that rows cannot be selected.
 */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = indexPath.row;

    NSLog(@"row selected:  %d",row);
    
    [delegate didTap:[NSNumber numberWithInt:row]];
        
	return nil;
}


- (void)dealloc {
	[arrayOfStrings release];
    [delegate release];
	[super dealloc];
}
	

@end
