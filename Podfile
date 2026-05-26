platform :ios, '16.0'

target 'MusicApp' do
  use_frameworks!

  pod "GCDWebServer/WebUploader", "~> 3.0"

  target 'MusicAppTests' do
    inherit! :search_paths
    pod "GCDWebServer/WebUploader", "~> 3.0"
  end

  target 'MusicAppUITests' do
    pod "GCDWebServer/WebUploader", "~> 3.0"
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
