Pod::Spec.new do |s|
  s.name          = 'ZLTestPods'
  s.version       = '0.2.9'
  s.summary       = 'test dependency'
  s.homepage      = 'https://github.com/longitachi/ZLTestPods'
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = {'longitachi' => 'longitachi@163.com'}
  s.source        = {:git => 'https://github.com/longitachi/ZLTestPods.git', :tag => s.version}
  
  s.ios.deployment_target = '10.0'

  s.swift_versions = ['5.0', '5.1', '5.2']

  s.resources     = 'Sources/*.{png,bundle}'

  s.requires_arc  = true
  s.frameworks    = 'UIKit','Photos','PhotosUI','AVFoundation','CoreMotion', 'Accelerate'

  s.resources     = 'Sources/*.{png,bundle}'

  s.subspec "Core" do |sp|
    sp.source_files  = ["Sources/**/*.swift", "Sources/ZLPhotoBrowser.h"]
  end

end
