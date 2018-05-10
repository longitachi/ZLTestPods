Pod::Spec.new do |s|
  s.name         = 'ZLTestPods'
  s.version      = '0.1.7'
  s.summary      = 'test dependency'
  s.homepage     = 'https://github.com/longitachi/ZLTestPods'
  s.license      = 'MIT'
  s.platform     = :ios
  s.author       = {'longitachi' => 'longitachi@163.com'}
  s.ios.deployment_target = '9.0'
  s.source       = {:git => 'https://github.com/longitachi/ZLTestPods.git', :tag => s.version}
  s.source_files = 'TestFolder/**/*.{h,m}'
  s.dependency 'SDWebImage'
  s.dependency 'GPUImage'
  s.requires_arc = true
end
