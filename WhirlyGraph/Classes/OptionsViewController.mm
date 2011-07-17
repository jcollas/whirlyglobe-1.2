
/*
 File: OptionsViewController.m
 Abstract: View controller that sets up the table view and serves as the table view's data source and delegate.
 Version: 2.1
 
 */

#import "OptionsViewController.h"

@implementation DBWrapper

static const char * const kQueryDataSetNames = "SELECT variable_name FROM data_sets;";
static const char * const kQueryJoin = "SELECT * FROM `measurements` INNER JOIN `nations` ON (`nations`.`id` = `measurements`.`nation_id`) INNER JOIN `data_sets` ON (`data_sets`.`id` = `measurements`.`data_set_id`)";

static const NSString * const kQueryFilterDataSetName = @"SELECT ##SELECT## FROM `measurements` INNER JOIN `nations` ON (`nations`.`id` = `measurements`.`nation_id`) INNER JOIN `data_sets` ON (`data_sets`.`id` = `measurements`.`data_set_id`) WHERE (`data_sets`.`variable_name` = '##NAME##');";

static const NSString * const kQueryFilterDataSetAndCountry = @"SELECT `measurement` FROM `measurements` INNER JOIN `nations` ON (`nations`.`id` = `measurements`.`nation_id`) INNER JOIN `data_sets` ON (`data_sets`.`id` = `measurements`.`data_set_id`) WHERE (`data_sets`.`variable_name` = '##DATASET##') AND (`nations`.`iso3` = '##ISO3##');";

// SELECT * FROM `measurements` INNER JOIN `nations` ON (`nations`.`id` = `measurements`.`nation_id`) INNER JOIN `data_sets` ON (`data_sets`.`id` = `measurements`.`data_set_id`) WHERE (`variable_name` = 'Population - Aged 0 - 14')"

// WHERE (`variable_name` = 'Population - Aged 0 - 14')


- (NSString *)queryWithSelection:(NSString *)selection name:(NSString *)name
{
    NSMutableString *s = [kQueryFilterDataSetName mutableCopy];
    [s replaceOccurrencesOfString:@"##SELECT##" withString:selection options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"##NAME##" withString:name options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    
    NSLog(@"%@", s);
    
    return (NSString *)[s autorelease];
}

- (NSString *)queryWithDataSetName:(NSString *)dataSetName country:(NSString *)iso3
{
    NSMutableString *s = [kQueryFilterDataSetAndCountry mutableCopy];
    [s replaceOccurrencesOfString:@"##DATASET##" withString:dataSetName options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"##ISO3##" withString:iso3 options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    return (NSString *)[s autorelease];
}


- (BOOL)open
{
    NSString *dbString = [[NSBundle mainBundle] pathForResource:@"une" ofType:@"sqlite3"];
    BOOL success = (sqlite3_open([dbString cStringUsingEncoding:1],&_db) != SQLITE_OK);
    
    if ( !success )
    {
        NSLog(@"Warning: SQLITE problem");
    }
    
    return success;        
}

- (NSArray *)dataSetNames
{
    NSMutableArray *names = [[NSMutableArray alloc] initWithCapacity:400];
    
    sqlhelpers::StatementRead readStmt(_db, kQueryDataSetNames);
    while ( readStmt.stepRow() )
    {
        [names addObject:readStmt.getString()];
    }
    
    [names addObject:@"None"];
    
    NSLog(@"names = %@", names);
    
    return (NSArray *)[names autorelease];
}

- (float)max:(NSString *)dataSetName
{
    
    NSString *query = [self queryWithSelection:@"max(`measurement`)" name:dataSetName];
    //NSString *query = MAX_DATASET_VALUE_QUERY(dataSetName);
    
    // query = @"SELECT max(measurement) FROM `measurements` INNER JOIN `nations` ON (`nations`.`id` = `measurements`.`nation_id`) INNER JOIN `data_sets` ON (`data_sets`.`id` = `measurements`.`data_set_id`) WHERE (`variable_name` = 'Population - Aged 0 - 14');";
    
    NSLog(@"query:\n%@\n", query);
    
    sqlhelpers::StatementRead readStmt(_db, query);
    float v = 0;
    while ( readStmt.stepRow() )
    {
        v = (float)readStmt.getDouble();
        break;
    }
    
    
    return v;
}

- (float)min:(NSString *)dataSetName
{
    NSString *query = [self queryWithSelection:@"min(`measurement`)" name:dataSetName];
    NSLog(@"query:\n%@\n", query);

    sqlhelpers::StatementRead readStmt(_db, query);
    
    float v = 0;
    while ( readStmt.stepRow() )
    {
        v = (float)readStmt.getDouble();
        break;
    }
    return v;
}

- (float)valueForDataSetName:(NSString *)dataSetName country:(NSString *)iso3Code
{
    NSString *query = [self queryWithDataSetName:dataSetName country:iso3Code];
 
    NSLog(@"query:\n%@\n", query);
    
    sqlhelpers::StatementRead readStmt(_db, query);
    
    float v = 0;
    while ( readStmt.stepRow() )
    {
        v = (float)readStmt.getDouble();
        break;
    }
    return v;
}


@end

@implementation OptionsViewController

@synthesize dataSetName = _dataSetName;
@synthesize arrayOfStrings;
@synthesize delegate;

- (void)viewDidLoad {
    
    if ( ! _db )
    {
        _db = [[DBWrapper alloc] init];
        [_db open];
    }
    
    self.arrayOfStrings = [_db dataSetNames];
}

- (NSDictionary *)getResult
{
    return nil;
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
    
    NSString *s = [arrayOfStrings objectAtIndex:indexPath.row];
    
    self.dataSetName = s;
    
    NSLog(@"Selected:  %@", self.dataSetName);
    NSLog(@"  max: %f", [_db max:self.dataSetName]);
    
    NSLog(@"  v: %f", [_db valueForDataSetName:self.dataSetName country:@"USA"]);
    
    [delegate didTap:self.dataSetName];
        
	return nil;
}


- (void)dealloc {
	[arrayOfStrings release];
    [delegate release];
	[super dealloc];
}
	

@end
