Pod::Spec.new do |s|
  s.name             = 'ARController'
  s.version          = '0.1.2'
  s.summary          = ' ARController. MVC on SceneNodes.'

  s.description      = <<-DESC
Idea is to provide to AR and Scene kit mechanism similar to  ViewController. Usually several application consist of several subsequent phases, or scenes.
Each scene happened insed same environment, sessions and objects however interactions between them, user actions and UI can vary.
                       DESC

  s.homepage         = 'https://github.com/Michael-Vorontsov/ARController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Michael Vorontsov' => 'michel06@ukr.net' }
  s.source           = { :git => 'https://github.com/Michael-Vorontsov/ARController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.source_files = 'ARController/Sources/**/*'
  
end
