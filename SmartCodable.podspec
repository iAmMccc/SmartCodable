#
# Be sure to run `pod lib lint SmartCodable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
## pod trunk register 邮箱名 'iAmMccc' --verbose
## pod me
## pod trunk push SmartCodable.podspec --allow-warnings


Pod::Spec.new do |s|
  s.name             = 'SmartCodable'
  s.version          = '5.1.0-beta'
  s.summary          = 'Swift数据解析库'
  
  s.homepage         = 'https://github.com/iAmMccc/SmartCodable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mccc' => 'https://github.com/iAmMccc' }
  s.source           = { :git => 'https://github.com/iAmMccc/SmartCodable.git', :tag => s.version.to_s }
  

  s.swift_version    = '5.0'

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = "12.0"
  s.osx.deployment_target = '10.13'
  s.watchos.deployment_target = '5.0'
  s.visionos.deployment_target = "1.0"

  s.default_subspecs = ['Core']


  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/SmartCodable/Core/**/*{.swift}'
  end
  
  
  s.subspec 'Inherit' do |ss|
      
    ss.ios.deployment_target = '13.0'
    ss.dependency 'SmartCodable/Core'
    ss.source_files = 'Sources/SmartCodable/MacroSupport/*{.swift}'
    
    # 这些配置项与宏相关，只放在 MacroSupport subspec 中
    ss.preserve_paths = ["Package.swift", "Sources/SmartCodableMacros", "Tests", "Bin"]

    ss.pod_target_xcconfig = {
      "OTHER_SWIFT_FLAGS" => "-Xfrontend -load-plugin-executable -Xfrontend $(PODS_BUILD_DIR)/SmartCodable/release/SmartCodableMacros-tool#SmartCodableMacros",
      "SUPPORTS_MACCATALYST" => "YES"
    }

    ss.user_target_xcconfig = {
      "OTHER_SWIFT_FLAGS" => "-Xfrontend -load-plugin-executable -Xfrontend $(PODS_BUILD_DIR)/SmartCodable/release/SmartCodableMacros-tool#SmartCodableMacros"
    }

    script = <<-SCRIPT
      env -i PATH="$PATH" "$SHELL" -l -c "swift build -c release --package-path \\"$PODS_TARGET_SRCROOT\\" --build-path \\"${PODS_BUILD_DIR}/SmartCodable\\""
    SCRIPT
  
    ss.script_phase = {
      :name => 'Build SmartCodable macro plugin',
      :script => script,
      :execution_position => :before_compile,
      :output_files => [
        "${PODS_BUILD_DIR}/SmartCodable/release/SmartCodableMacros-tool"
      ]
    }
  end
end


