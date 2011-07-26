
/*
     File: OptionsViewController.h
 Abstract: View controller that sets up the table view and serves as the table view's data source and delegate.
  Version: 2.1
 
 
 */

#import <UIKit/UIKit.h>
#import "sqlite3.h"
#import <sqlhelpers.h>

@interface DBWrapper : NSObject {
@private
    sqlite3* _db;
}
- (NSString *)queryWithSelection:(NSString *)selection name:(NSString *)name;
- (NSString *)queryWithSelection:(NSString *)selection name:(NSString *)name;
- (BOOL)open;
- (NSArray *)dataSetNames;
- (NSNumber *)max:(NSString *)dataSetName;
- (NSNumber *)min:(NSString *)dataSetName;
- (NSNumber *)valueForDataSetName:(NSString *)dataSetName country:(NSString *)iso3Code;
@end

@protocol OptionsViewControllerDelegate <NSObject>

-(void)didTap:(NSString *)queryString;

@end

@class DBWrapper;

@interface OptionsViewController : UITableViewController {
    
    DBWrapper* _db;
    NSString* _dataSetName;
    
    NSArray *arrayOfStrings;
    id delegate;
}

@property (nonatomic, copy) NSString * dataSetName;

@property (nonatomic, retain) NSArray *arrayOfStrings;
@property (nonatomic, assign) id<OptionsViewControllerDelegate> delegate;

@end