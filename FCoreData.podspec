#
# Be sure to run `pod lib lint Alich.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#


Pod::Spec.new do |s|
  s.name             = 'FCoreData'
  s.version          = '0.0.2'
  s.swift_version    = '4.2'
  s.summary          = 'Forob core data library'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The core data library. Using easy. Clean model.
                       DESC

  s.homepage         = 'https://bitbucket.org/shohin/fcoredata'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Shohin' => 'tagayev.shohin@gmail.com' }
  s.source           = { :git => 'https://shohin@bitbucket.org/shohin/fcoredata.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'

  s.source_files = 'FCoreData/sources/**/*'
end