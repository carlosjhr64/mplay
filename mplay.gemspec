Gem::Specification.new do |s|

  s.name     = 'mplay'
  s.version  = '3.1.0'

  s.homepage = 'https://github.com/carlosjhr64/mplay'

  s.author   = 'carlosjhr64'
  s.email    = 'carlosjhr64@gmail.com'

  s.date     = '2017-12-12'
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
  )
  s.executables << 'mplay'
  s.add_runtime_dependency 'gtk3app', '~> 2.0', '>= 2.0.1'
  s.add_runtime_dependency 'helpema', '~> 1.0', '>= 1.0.1'
  s.add_runtime_dependency 'base_convert', '~> 2.2', '>= 2.2.0'
  s.requirements << 'ruby: ruby 2.4.2p198 (2017-09-14 revision 59899) [x86_64-linux]'
  s.requirements << 'youtube-dl: 2017.11.15'
  s.requirements << 'mplayer: MPlayer 1.3.0-7 (C) 2000-2016 MPlayer Team'
  s.requirements << 'wget: GNU Wget 1.19.2 built on linux-gnu.'
  s.requirements << 'tee: tee (GNU coreutils) 8.27'
  s.requirements << 'system: linux/bash'

end
