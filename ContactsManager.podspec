Pod::Spec.new do |s|
 
    s.name         = "Contacts Manager"
    s.version      = "0.1"
    s.summary      = "Obtain and manage your device contacts in a easy way."
    s.homepage     = "https://github.com/Kekiiwaa/ContactsManager"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = "Sebastian Gomez Osorio"
    s.source       = { :git => "https://github.com/Kekiiwaa/ContactsManager.git", :tag => "0.1" }
    s.source_files = "ContactsManager", "ContactsManager/*.{h,m}"
    s.frameworks   = 'UIKit'
    s.ios.deployment_target = '7.0'
    s.platform = :ios, '7.0'
    s.requires_arc = false
 
end