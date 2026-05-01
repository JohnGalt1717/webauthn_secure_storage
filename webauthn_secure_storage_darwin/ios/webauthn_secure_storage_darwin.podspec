Pod::Spec.new do |s|
  s.name             = 'webauthn_secure_storage_darwin'
  s.version          = '0.1.0'
  s.summary          = 'Darwin implementation for webauthn_secure_storage.'
  s.description      = <<-DESC
Darwin implementation for webauthn_secure_storage.
                       DESC
  s.homepage         = 'https://github.com/JohnGalt1717/webauthn_secure_storage'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'JohnGalt1717' => 'JohnGalt1717@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'webauthn_secure_storage_darwin/Sources/webauthn_secure_storage_darwin/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
