//
//  ViewController.m
//  Demo
//
//  Created by Sebastián Gómez on 25/04/15.
//  Copyright (c) 2015 Sebastián Gómez. All rights reserved.
//

#import "ViewController.h"
#import "KTSContactsManager.h"

@interface ViewController () <KTSContactsManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *tableData;
@property (strong, nonatomic) KTSContactsManager *contactsManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contactsManager = [KTSContactsManager sharedManager];
    self.contactsManager.delegate = self;
    self.contactsManager.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES] ];
    [self loadData];
}

- (void)loadData
{
    [self.contactsManager importContacts:^(NSArray *contacts)
     {
         self.tableData = contacts;
         [self.tableView reloadData];
         NSLog(@"contacts: %@",contacts);
     }];
}

-(void)addressBookDidChange
{
    NSLog(@"Address Book Change");
    [self loadData];
}

-(BOOL)filterToContact:(NSDictionary *)contact
{
    return YES;
    return ![contact[@"company"] isEqualToString:@""];
}

- (IBAction)addContact:(UIBarButtonItem *)sender
{
    [self.contactsManager addContactName:@"John"
                                lastName:@"Smith"
                                  phones:@[@{
                                               @"value":@"+7-903-469-97-48",
                                              @"label":@"Mobile"
                                               }]
                                  emails:@[@{
                                               @"value":@"mail@mail.com",
                                               @"label": @"home e-mail"
                                               }]
                                birthday:[NSDate dateWithTimeInterval:22 * 365 * 24 * 60 * 60 sinceDate:[NSDate date]]
                                   image:[UIImage imageNamed:@"newContact"]
                              completion:^(BOOL wasAdded) {
                                  NSLog(@"Contact was %@ added",wasAdded ? @"" : @"NOT");
                              }];
}

#pragma mark - TableView Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell"];
    
    NSDictionary *contact = [self.tableData objectAtIndex:indexPath.row];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    NSString *firstName = contact[@"firstName"];
    nameLabel.text = [firstName stringByAppendingString:[NSString stringWithFormat:@" %@", contact[@"lastName"]]];
    
    UILabel *phoneNumber = (UILabel *)[cell viewWithTag:2];
    NSArray *phones = contact[@"phones"];
    
    if ([phones count] > 0) {
        NSDictionary *phoneItem = phones[0];
        phoneNumber.text = phoneItem[@"value"];
    }
    
    UIImageView *cellIconView = (UIImageView *)[cell.contentView viewWithTag:888];
    
    cellIconView.image = contact[@"image"] ? : [UIImage imageNamed:@"contact_icon"];
    cellIconView.contentScaleFactor = UIViewContentModeScaleAspectFill;
    cellIconView.layer.cornerRadius = CGRectGetHeight(cellIconView.frame) / 2;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData count];
}

@end
