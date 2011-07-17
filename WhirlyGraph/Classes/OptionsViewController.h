
/*
     File: OptionsViewController.h
 Abstract: View controller that sets up the table view and serves as the table view's data source and delegate.
  Version: 2.1
 
 
 */

#import <UIKit/UIKit.h>

@protocol OptionsViewControllerDelegate <NSObject>

-(void)didTap:(NSNumber *)string;

@end

@interface OptionsViewController : UITableViewController {
    
    NSMutableArray *arrayOfStrings;
    id delegate;
    
}

@property (nonatomic, retain) NSMutableArray *arrayOfStrings;
@property (nonatomic, assign) id<OptionsViewControllerDelegate> delegate;

@end