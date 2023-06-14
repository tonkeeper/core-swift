Pod::Spec.new do |s|
  s.name             = 'WalletCoreSwift'
  s.version          = '0.0.1'
  s.homepage         = 'https://github.com/tonkeeper/core-swift'
  s.source           = { :git => 'https://github.com/tonkeeper/core-swift.git', :tag => s.version.to_s }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sergey Kotov' => 'kotov@tonkeeper.com', 'Oleg Andreev' => 'oleg@tonkeeper.com', 'Grigory Serebryanyy' => 'serebryanyy@tonkeeper.com' }
  s.summary          = 'This is a pure Swift implementation of Tonkeeper Core.'
  s.description      = 'This is a pure Swift implementation of Tonkeeper Core: complete wallet implementation as an embeddable library. The goal of the library is to provide strictly-typed definition of the wallet behaviors that is easier to audit and cover with automated tests.'
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  
  s.source_files = ["Source/*.{swift,h}", "Source/**/*.{swift,c,h}"]

  s.dependency 'TonSwift'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = ["Tests/*.{swift,h}", "Tests/**/*.{swift,c,h}", "Tests/**/**/*.{swift,c,h}"]
    test_spec.frameworks = 'XCTest'
  end
  
end