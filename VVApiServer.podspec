
Pod::Spec.new do |spec|
  spec.name         = "VVApiServer"
  spec.version      = "0.0.4"
  spec.summary      = "自定义本地和远程Api接口访问结果，同时支持Unit Test"
  spec.homepage     = "https://github.com/chinaxxren/VVApiServer"
  spec.license      = "MIT"
  spec.author       = { "chinaxxren" => "182421693@qq.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/chinaxxren/VVApiServer.git", :tag => "#{spec.version}" }
  spec.source_files  = "VVApiServer/Source/**/*.{h,m}"
  spec.frameworks  = "UIKit"
  spec.dependency  "CocoaAsyncSocket"
  spec.dependency "AFNetworking"
end
