module Mplay
  VERSION = '3.1.0'
end

# Gtk2App
require 'gtk3app'

# Standard
require 'digest'
require 'uri'
require 'fileutils'
require 'date'
require 'find'
require 'cgi'

# Gems
require 'helpema'
require 'base_convert'

# This Gem:
require_relative 'mplay/config.rb'
require_relative 'mplay/such_parts.rb'
require_relative 'mplay/mplay.rb'

# Requires:
#`ruby`
#`youtube-dl`
#`mplayer`
#`wget`
#`tee`
#`system`
