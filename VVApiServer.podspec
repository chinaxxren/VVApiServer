
Pod::Spec.new do |spec|
  spec.name         = "VVApiServer"
  spec.version      = "0.0.1"
  spec.summary      = "VVORM 封装FMDB数据库操作"
  spec.homepage     = "https://github.com/chinaxxren/VVApiServer"
  spec.license      = "MIT"
  spec.author       = { "chinaxxren" => "182421693@qq.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/chinaxxren/VVApiServer.git", :tag => "#{spec.version}" }
  spec.source_files  = "VVApiServer/Source/**/*.{h,m}"
  spec.frameworks  = "UIKit"
  spec.dependency  "CocoaAsyncSocket"
end
