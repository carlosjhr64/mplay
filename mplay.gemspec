Gem::Specification.new do |s|

  s.name     = 'mplay'
  s.version  = '3.0.1'

  s.homepage = 'https://github.com/carlosjhr64/mplay'

  s.author   = 'carlosjhr64'
  s.email    = 'carlosjhr64@gmail.com'

  s.date     = '2017-08-24'
  s.licenses = ['MIT']

  s.description = <<DESCRIPTION
A gtk3app youtube-dl and mplayer manager/gui.
DESCRIPTION

  s.summary = <<SUMMARY
A gtk3app youtube-dl and mplayer manager/gui.
SUMMARY

  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options     = ['--main', 'README.rdoc']

  s.require_paths = ['lib']
  s.files = %w(
README.rdoc
bin/mplay
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
  s.executables << 'mplay'
  s.add_runtime_dependency 'gtk3app', '~> 2.0', '>= 2.0.0'
  s.add_runtime_dependency 'helpema', '~> 0.2', '>= 0.2.0'
  s.add_runtime_dependency 'base_convert', '~> 2.0', '>= 2.0.0'
  s.requirements << 'ruby: ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-linux]'
  s.requirements << 'youtube-dl: 2017.06.23'
  s.requirements << 'mplayer: MPlayer 1.3.0-7 (C) 2000-2016 MPlayer Team'
  s.requirements << 'wget: GNU Wget 1.19.1 built on linux-gnu.'
  s.requirements << 'tee: tee (GNU coreutils) 8.27'
  s.requirements << 'system: linux/bash'

end
