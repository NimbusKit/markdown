Pod::Spec.new do |s|
  s.name     = 'NimbusKit-markdown'
  s.version  = '0.0.2'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'A Markdown NSAttributedString parser.'
  s.author   = { "Jeff Verkoeyen" => "jverkoey@gmail.com" }
  s.homepage = 'https://github.com/jverkoey/NSAttributedStringMarkdownParser'
  s.source   = { :git => 'https://github.com/epyx-src/markdown.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'

  s.public_header_files = 'src/**/*.h'
  s.source_files = 'src/**/*.{h,m}'

  s.dependency 'fmemopen', '~> 0.0.1'

end
