# ContactsManager Objective C

## Usage

ContactsManager is a delightful library for iOS. It's built with high quality standards to optimize the performance of your application and get your contacts quickly and safely.

Choose ContactsManager for your next project, or migrate over your existing projects, we guarantee you'll be happy you did!

## How To Get Started

> Download ContactsManager and try out the included iPhone Demo

## Installation

> Using Cocoapods
> Copying all the files into your project

### CocoaPods:
ContactsManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "ContactsManager"

After this import ContactsManager: "#import "ContactsManager/KTSContactsManager.h"

### Copying files into your project

1. Drag and Drop ContactsManager folder into your project
2. In "Choose options dialog" check "Copy items if needed" and select "Create Groups" option, then press finish Button.
3. In the Class that you want get the device contacts, import ContactsManager: ```#import "ContactsManager/KTSContactsManager.h```

## Usage

### Import All Contacts:
```
[KTSContactsManager importContacts:^(NSArray *contacts) {
        NSLog(@"contacts: %@",contacts);
    }];
```

### Add new Contact
```
[KTSContactsManager addContactName: @"Tefany"
                              lastName: @"Jhonson"
                                phones: @[@{@"label":@"mobile",@"value":@"731782982"}]
                                emails: @[@{@"label":@"work",@"value":@"tefany@work.com"}]
                              birthday: nil completion:^(BOOL wasAdded) {
                                  
        NSLog(@"%i",wasAdded);
                                  
    }];
```

### Remove Contact
```
[KTSContactsManager removeContactById:184 completion:^(BOOL wasRemoved) {
        NSLog(@"%i",wasRemoved);
    }];
```

## Author

Kekiiwaa Inc, 
sebastiangomez989@gmail.com

## License

ContactsManager is available under the MIT license. See the LICENSE file for more info.

