//
//  KTSContactsManager.m
//  kontacts-objc
//
//  Created by Sebastián Gómez on 19/04/15.
//  Copyright (c) 2015 Sebastián Gómez. All rights reserved.
//

#import "KTSContactsManager.h"

@interface KTSContactsManager ()

@property (assign, nonatomic) ABAddressBookRef addressBook;

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

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        CFErrorRef *error = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, error);
        [self startObserveAddressBook];
        self.sortDescriptors = @[];
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
        person[@"firstName"] = [self stringProperty:kABPersonFirstNamePhoneticProperty fromContact:record];
        
        // LastName
        person[@"lastName"] = [self stringProperty:kABPersonLastNameProperty fromContact:record];
        
        // middleName
        person[@"middleName"] = [self stringProperty:kABPersonMiddleNameProperty fromContact:record];
        
        // prefix
        person[@"prefix"] = [self stringProperty:kABPersonPrefixProperty fromContact:record];
        
        // suffix
        person[@"suffix"] = [self stringProperty:kABPersonSuffixProperty fromContact:record];
        
        // firstNamePhonetic
        person[@"firstNamePhonetic"] = [self stringProperty:kABPersonFirstNamePhoneticProperty fromContact:record];
        
        // lastNamePhonetic
        person[@"lastNamePhonetic"] = [self stringProperty:kABPersonLastNamePhoneticProperty fromContact:record];
        
        // nickName
        person[@"nickName"] = [self stringProperty:kABPersonNicknameProperty fromContact:record];
        
        // company
        person[@"company"] = [self stringProperty:kABPersonOrganizationProperty fromContact:record];
        
        // jobTitle
        person[@"jobTitle"] = [self stringProperty:kABPersonJobTitleProperty fromContact:record];
        
        // department
        person[@"department"] = [self stringProperty:kABPersonDepartmentProperty fromContact:record];
        
        // note
        person[@"note"] = [self stringProperty:kABPersonNoteProperty fromContact:record];
        
        // createdAt
        person[@"createdAt"] = [self dateProperty:kABPersonCreationDateProperty fromContact:record];
        
        // updatedAt
        person[@"updatedAt"] = [self stringProperty:kABPersonModificationDateProperty fromContact:record];
        
        // BirthDay
        person[@"birthday"] = [self stringProperty:kABPersonBirthdayProperty fromContact:record];
        
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
            
    [importedContacts sortUsingDescriptors:self.sortDescriptors];
    
    return importedContacts;
}

-(NSString *)stringProperty:(ABPropertyID)property fromContact:(ABRecordRef)person
{
    CFTypeRef companyCFObject = ABRecordCopyValue(person, property);
    return (companyCFObject != nil) ? (__bridge NSString *)companyCFObject : @"";
}

-(NSDate *)dateProperty:(ABPropertyID)property fromContact:(ABRecordRef)person
{
    CFTypeRef companyCFObject = ABRecordCopyValue(person, property);
    return (companyCFObject != nil) ? (__bridge NSDate *)companyCFObject : [NSDate dateWithTimeIntervalSince1970:1];
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
