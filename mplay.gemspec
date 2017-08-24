Gem::Specification.new do |s|

  s.name     = 'mplay'
  s.version  = '2.6.0'

  s.homepage = 'https://github.com/carlosjhr64/mplay'

  s.author   = 'carlosjhr64'
  s.email    = 'carlosjhr64@gmail.com'

  s.date     = '2016-01-20'
  s.licenses = ['MIT']

  s.description = <<DESCRIPTION
A gtk3app youtube-dl and mplayer manager/gui.
DESCRIPTION

  s.summary = <<SUMMARY
A gtk3app youtube-dl and mplayer manager/gui.
SUMMARY

  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options     = ["--main", "README.rdoc"]

  s.require_paths = ["lib"]
  s.files = %w(
README.rdoc
data/VERSION
data/downloading.png
data/high.png
data/logo.png
data/low.png
data/playing.png
lib/mplay.rb
lib/mplay/config.rb
lib/mplay/mplay.rb
lib/mplay/such_parts.rb
lib/mplay/version.rb
  )

  s.add_runtime_dependency 'helpema', '~> 0.1', '>= 0.1.0'
  s.add_runtime_dependency 'base_convert', '~> 2.0', '>= 2.0.0'
  s.requirements << 'ruby: ruby 2.2.4p230 (2015-12-16 revision 53155) [x86_64-linux]'
  s.requirements << 'gtk3app: 1.5.1'
  s.requirements << 'youtube-dl: 2015.12.18'
  s.requirements << 'mplayer: MPlayer SVN-r37150-4.8.3 (C) 2000-2014 MPlayer Team'
  s.requirements << 'wget: GNU Wget 1.16.1 built on linux-gnu.'
  s.requirements << 'tee: tee (GNU coreutils) 8.21'
  s.requirements << 'system: linux/bash'

end
