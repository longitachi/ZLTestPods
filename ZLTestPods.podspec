Pod::Spec.new do |s|
  s.name         = 'TestFolder'
  s.version      = '0.1.0'
  s.summary      = 'test dependency'
  s.homepage     = 'https://github.com/longitachi/ZLTestPods'
  s.license      = 'MIT'
  s.platform     = :ios
  s.author       = {'longitachi' => 'longitachi@163.com'}
  s.ios.deployment_target = '9.0'
  s.source       = {:git => 'https://github.com/longitachi/ZLTestPods.git', :tag => s.version}
  s.source_files = 'TestFolder/*.{h,m}'
  s.dependency 'YYWebImage'
  s.requires_arc = true
end
