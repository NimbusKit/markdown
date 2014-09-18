Pod::Spec.new do |s|
  s.name         = "markdown-parser"
  s.version      = "0.1"
  s.summary      = "A Markdown NSAttributedString parser."

  s.description  = <<-DESC
                    This is a Markdown => NSAttributedString parser built on top
                    of a flex parser. It takes an NSString and returns an
                    NSAttributedString with markdown tags replaced by CoreText
                    formatting attributes.
                   DESC

  s.homepage     = "https://github.com/xing/markdown-parser/"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Jeff Verkoeyen" => "jverkoey@gmail.com" }
  s.platform     = :ios
  s.source       = { :git => "git@source.xing.com:ios-pods/markdown-parser.git", :tag => s.version.to_s }
  s.source_files = 'src/**/*.{h,m}'
  s.dependency 'fmemopen'
  s.requires_arc = true
end
