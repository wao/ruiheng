$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Ruiheng
  VERSION = '0.0.1'
end

require 'ruiheng/media_mgr'
