//
//  KTSContactsManager.m
//  kontacts-objc
//
//  Created by Sebastián Gómez on 19/04/15.
//  Copyright (c) 2015 Sebastián Gómez. All rights reserved.
//

#import "KTSContactsManager.h"

@interface KTSContactsManager ()

@property (nonatomic) ABAddressBookRef addressBook;

@end

@implementation KTSContactsManager

+ (instancetype)sharedManager
{
    static KTSContactsManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        CFErrorRef *error = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, error);
        [self startObserveAddressBook];
    }
    
    return self;
}

- (void)importContacts:(void (^)(NSArray *))contactsHandler
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Address Book Access Denied" message:@"Please grant us access to your Address Book in Settings -> Privacy -> Contacts" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        CFErrorRef *error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted)
            {
                NSMutableArray *contactsList = [(__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook) mutableCopy];
                contactsHandler([[NSArray alloc] initWithArray:[self extractContactsInDictionary:contactsList]]);
            }
        });
        return;
    }
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        CFErrorRef *error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
        NSMutableArray *contactsList = [(__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook) mutableCopy];
        contactsHandler([[NSArray alloc] initWithArray:[self extractContactsInDictionary:contactsList]]);
        return;
    }
}

- (NSMutableArray *)extractContactsInDictionary:(NSMutableArray *)contactsList
{
    NSMutableArray *importedContacts = [[NSMutableArray alloc] init];
    
    [contactsList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ABRecordRef record = (__bridge ABRecordRef)obj;
        NSMutableDictionary *person = [[NSMutableDictionary alloc] init];
        
        // Contact ID
        ABRecordID contactID = ABRecordGetRecordID(record);
        person[@"id"] = [NSString stringWithFormat:@"%d", contactID];
        
        // FirstName
        CFTypeRef firstNameCFObject = ABRecordCopyValue(record, kABPersonFirstNameProperty);
        person[@"firstName"] = (firstNameCFObject != nil) ? (__bridge NSString *)firstNameCFObject : @"";
        
        // LastName
        CFTypeRef lastNameCFObject = ABRecordCopyValue(record, kABPersonLastNameProperty);
        person[@"lastName"] = (lastNameCFObject != nil) ? (__bridge NSString *)lastNameCFObject : @"";
        
        // Company
        CFTypeRef companyCFObject = ABRecordCopyValue(record, kABPersonOrganizationProperty);
        person[@"company"] = (companyCFObject != nil) ? (__bridge NSString *)companyCFObject : @"";
        
        // Phone(s)
        ABMultiValueRef phones = ABRecordCopyValue(record, kABPersonPhoneProperty);
        NSMutableArray *phonesArray = [[NSMutableArray alloc] init];
        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
        {
            NSString *phoneNumber = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j));
            NSString *label = (__bridge NSString *)(ABMultiValueCopyLabelAtIndex(phones, j));
            NSDictionary *phoneItem = @{
                                        @"label" : (label != nil) ? [self getKeyFromLabel:label] : @"",
                                        @"value" : phoneNumber
                                        };
            [phonesArray addObject:phoneItem];
        }
        person[@"phones"] = phonesArray;
        
        // Email(s)
        ABMultiValueRef emails = ABRecordCopyValue(record, kABPersonEmailProperty);
        NSMutableArray *emailsArray = [[NSMutableArray alloc] init];
        for(CFIndex j = 0; j < ABMultiValueGetCount(emails); j++)
        {
            NSString *email = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(emails, j));
            NSString *label = (__bridge NSString *)(ABMultiValueCopyLabelAtIndex(emails, j));
            NSDictionary *emailItem = @{
                                        @"label" : (label != nil) ? [self getKeyFromLabel:label] : @"",
                                        @"value" : email
                                        };
            [emailsArray addObject:emailItem];
        }
        person[@"emails"] = emailsArray;
        
        // BirthDay
        NSDate *birthday = (__bridge NSDate *)(ABRecordCopyValue(record, kABPersonBirthdayProperty));
        person[@"birthday"] = (birthday != nil) ? birthday : @"";
        
        BOOL add = YES;
        
        if([self.delegate respondsToSelector:@selector(filterToContact:)])
        {
            add = [self.delegate filterToContact:person];
        }
        
        if(add)
        {
            [importedContacts addObject:person];
        }
        
    }];
    
    return importedContacts;
}

- (NSString *)getKeyFromLabel:(NSString *)label
{
    if (![label containsString:@"<"])
    {
        return label;
    }
    NSRange startCharacter = [label rangeOfString:@"<"];
    NSRange endCharacter = [label rangeOfString:@">"];
    NSString *clearText = [label substringWithRange:NSMakeRange(startCharacter.location + 1, (endCharacter.location - startCharacter.location) - 1)];
    return clearText;
}

- (void)addContactName:(NSString *)firstName lastName:(NSString *)lastName phones:(NSArray *)phonesList emails:(NSArray *)emailsList birthday:(NSDate *)birthday completion:(void (^)(BOOL))added
{
    CFErrorRef *error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
    
    CFErrorRef *anError = nil;
    ABRecordRef record = ABPersonCreate();
    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstName), anError);
    ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFTypeRef)(lastName), anError);

    [phonesList enumerateObjectsUsingBlock:^(NSDictionary *phone, NSUInteger idx, BOOL *stop) {
        ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phone[@"value"]), (__bridge CFStringRef)(phone[@"label"]), NULL);
        ABRecordSetValue(record, kABPersonPhoneProperty, multiPhone, nil);
    }];
    
    [emailsList enumerateObjectsUsingBlock:^(NSDictionary *email, NSUInteger idx, BOOL *stop) {
        ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(multiEmail, (__bridge CFTypeRef)(email[@"value"]), (__bridge CFStringRef)(email[@"label"]), NULL);
        ABRecordSetValue(record, kABPersonEmailProperty, multiEmail, nil);
    }];
    
    bool wasAdded = ABAddressBookAddRecord(addressBook, record, error);
    
    if (wasAdded) {
        NSLog(@"New record added");
    }
    
    bool wasSaved = ABAddressBookSave(addressBook, nil);
    
    if (wasSaved) {
        NSLog(@"Address book saved");
    }
    
    added(wasSaved);
}

- (void)removeContactById:(NSInteger)contactID completion:(void (^)(BOOL))removed
{
    CFErrorRef *error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
    ABRecordID recordID = (ABRecordID)contactID;
    ABRecordRef contactRef = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(contactRef, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge NSString *)ABRecordCopyValue(contactRef, kABPersonLastNameProperty);
    if (!lastName) {
        lastName = @"";
    }
    NSLog(@"Contact to be deleted: %@" ,[firstName stringByAppendingString:lastName]);
    
    
    BOOL recordDeleted = ABAddressBookRemoveRecord(addressBook, contactRef, error);
    if (recordDeleted) {
        NSLog(@"Record removed");
    }
    
    ABAddressBookSave(addressBook, nil);
    removed(recordDeleted);
}

#pragma mark - Observers

- (void)startObserveAddressBook
{
    ABAddressBookRegisterExternalChangeCallback(self.addressBook, addressBookExternalChange, (__bridge void *)(self));
}

#pragma mark - external change callback

void addressBookExternalChange(ABAddressBookRef __unused addressBookRef, CFDictionaryRef __unused info, void *context)
{
    KTSContactsManager *manager = (__bridge KTSContactsManager *)(context);
    if([manager.delegate respondsToSelector:@selector(addressBookDidChange)])
    {
        [manager.delegate addressBookDidChange];
    }
}

@end
