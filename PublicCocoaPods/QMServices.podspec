#
#  Be sure to run `pod spec lint QMServices.podspec --verbose --use-libraries --allow-warnings' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
#  To submit use `pod trunk push QMServices.podspec --verbose --use-libraries --allow-warnings`
#


Pod::Spec.new do |s|
    s.name         = "QMServices"
    s.version      = "0.5.5"
    s.summary      = "Easy-to-use services for Quickblox SDK, for speeding up development of iOS chat applications."
    s.homepage     = "https://github.com/QuickBlox/q-municate-services-ios"
    s.license      = { :type => 'BSD', :file => 'LICENSE.txt' }
    s.authors      = {"Andrey Ivanov" => "andrey.ivanov@quickblox.com", "Vitaliy Gorbachov" => "vitaliy.gorbachov@quickblox.com", "Vitaliy Gurkovsky" => "vitaliy.gurkovsky@injoit.com"}
    s.platform     = :ios, "8.0"
    s.source       = { :git => "https://github.com/QuickBlox/q-municate-services-ios.git", :tag => "#{s.version}"}
    s.source_files  = "Classes", "**/*.{h,m}"
    s.exclude_files = "Pods", "Frameworks"
    s.frameworks = "CoreData"
    s.requires_arc = true
    s.xcconfig = { "FRAMEWORK_SEARCH_PATHS" => "$(PODS_ROOT)/QuickBlox/" }
    s.prefix_header_contents =
    '#import <Quickblox/Quickblox.h>
    #import <CoreData/CoreData.h>
    #import <Quickblox/QBMulticastDelegate.h>
    #import <Bolts/Bolts.h>'

    s.resource_bundle = {
        'QMChatCacheModel' => 'QMChatCache/QMChatCache/CoreData/QMChatServiceModel.xcdatamodeld',
        'QMContactListCacheModel' => 'QMContactListCache/QMContactListCache/CoreData/QMContactListModel.xcdatamodeld',
        'QMUsersCacheModel' => 'QMUsersCache/QMUsersCache/CoreData/QMUsersModel.xcdatamodeld',
        'QMOpenGraphCacheModel' => 'QMOpenGraphCache/QMOpenGraphCache/CoreData/QMOpenGraphModel.xcdatamodeld'
        }

    s.dependency "QuickBlox", ">= 2.11"
    s.dependency "Bolts",  '>= 1.8.4'
end
