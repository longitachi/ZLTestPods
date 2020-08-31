Pod::Spec.new do |s|
  s.name          = 'ZLTestPods'
  s.version       = '0.2.2'
  s.summary       = 'test dependency'
  s.homepage      = 'https://github.com/longitachi/ZLTestPods'
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = {'longitachi' => 'longitachi@163.com'}
  s.source        = {:git => 'https://github.com/longitachi/ZLTestPods.git', :tag => s.version}
  
  s.ios.deployment_target = '10.0'

  s.swift_version = '5.0'

  s.source_files  = 'Source/**/*.swift'
  s.resources     = 'Source/*.{png,bundle}'

  s.requires_arc  = true
  s.frameworks    = 'UIKit','Photos','PhotosUI','AVFoundation','CoreMotion'

end
