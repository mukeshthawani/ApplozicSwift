Pod::Spec.new do |s|
  s.name = 'ApplozicSwift'
  s.version = '3.2.0'
  s.license = { :type => "BSD 3-Clause", :file => "LICENSE" }
  s.summary = 'Applozic Swift Kit'
  s.homepage = 'https://github.com/AppLozic/ApplozicSwift'
  s.social_media_url = 'http://twitter.com/AppLozic'
  s.authors = { 'Applozic Inc.' => 'support@applozic.com' }

  s.source = { :git => 'https://github.com/AppLozic/ApplozicSwift.git', :tag => s.version }

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'

  s.default_subspec = 'Complete'

  s.subspec 'RichMessageKit' do |richMessage|
    richMessage.source_files = 'RichMessageKit/**/*.swift'
    richMessage.resources = 'RichMessageKit/**/*{xcassets}'
  end

  s.subspec 'Complete' do |complete|
    complete.source_files = 'Sources/**/*.swift'
    complete.resources = 'Sources/**/*{lproj,storyboard,xib,xcassets,json}'
    complete.dependency 'Kingfisher', '~> 5.7.0'
    complete.dependency 'MGSwipeTableCell', '~> 1.6.8'
    complete.dependency 'DifferenceKit', '~> 1.0'
    complete.dependency 'Applozic', '~> 6.14.0'
    complete.dependency 'ApplozicSwift/RichMessageKit'
  end
end
