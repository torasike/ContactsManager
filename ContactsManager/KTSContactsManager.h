//
//  KTSContactsManager.h
//  kontacts-objc
//
//  Created by Sebastián Gómez on 19/04/15.
//  Copyright (c) 2015 Sebastián Gómez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <UIKit/UIKit.h>

@protocol KTSContactsManagerDelegate <NSObject>

-(void)addressBookDidChange;
-(BOOL)filterToContact:(NSDictionary *)contact;

@end

@interface KTSContactsManager : NSObject

@property (assign, nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) id<KTSContactsManagerDelegate> delegate;
@property (strong, nonatomic) NSArray *sortDescriptors;

+ (id)sharedManager;

- (void)importContacts:(void (^)(NSArray *contacts))contactsHandler;
- (void)addContactName:(NSString *)firstName lastName:(NSString *)lastName phones:(NSArray *)phonesList emails:(NSArray *)emailsList birthday:(NSDate *)birthday completion:(void (^)(BOOL wasAdded))added;
- (void)removeContactById:(NSInteger)contactID completion:(void (^)(BOOL wasRemoved))removed;

@end
