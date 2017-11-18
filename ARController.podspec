#
# Be sure to run `pod lib lint ARController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ARController'
  s.version          = '0.1.2'
  s.summary          = ' ARController. MVC on SceneNodes.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Idea is to provide to AR and Scene kit mechanism similar to  ViewController. Usually several application consist of several subsequent phases, or scenes.
Each scene happened insed same environment, sessions and objects however interactions between them, user actions and UI can vary.
                       DESC

  s.homepage         = 'https://github.com/Michael-Vorontsov/ARController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Michael Vorontsov' => 'mykhailov@starsgroup.com' }
  s.source           = { :git => 'https://github.com/Michael-Vorontsov/ARController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.source_files = 'ARController/Sources/**/*'
  
end
