Pod::Spec.new do |spec|
  spec.name         = "AegisAuth"
  spec.version      = "1.0.0"
  spec.summary      = "Aegis Auth iOS SDK - Unified identity management system"
  spec.description  = <<-DESC
                      Aegis Auth is a unified identity management system providing secure iOS authentication.
                      Consolidation of disparate identity providers into a single canonical source.
                      DESC

  spec.homepage     = "https://github.com/navchetnaofficialllp/aegis-auth-sdk-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Navchetna Technologies" => "hello@navchetna.tech" }

  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.15"
  spec.watchos.deployment_target = "6.0"
  spec.tvos.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/navchetnaofficialllp/aegis-auth-sdk-ios.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/**/*.swift"
  spec.swift_version = "5.9"

  spec.dependency "Alamofire", "~> 5.8"
  spec.dependency "SwiftyJSON", "~> 5.0"
end