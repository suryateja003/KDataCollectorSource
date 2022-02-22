Pod::Spec.new do |s|
s.name = 'KDataTest'
s.version = ‘0.1’
s.summary = ‘Data collector SDK.’
s.description = ‘this pod is used to collect the Data’
s.homepage = ‘https://github.com/suryateja003/KDataCollectorSource'
s.license = { :type => ‘MIT’, :file => ‘LICENSE’ }
s.author = { ‘surya’ => ‘vellaturi.d@intimetec.com’ }
s.source = { :git => ‘https://github.com/suryateja003/KDataCollectorSource.git', :tag => s.version. }
s.vendored_frameworks = ‘KDataTest.xcframework’
s.platform = :ios
s.ios.deployment_target = ‘9.3’
# s.swift_version = “4.2”
s.pod_target_xcconfig = { ‘ONLY_ACTIVE_ARCH’ => ‘YES’ }
end