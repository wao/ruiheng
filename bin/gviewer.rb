#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + "/../lib"

require 'ui/gtk3/global'

if File.directory? ARGV[0]
    Global.create_inst(ARGV[0])
    Global.inst.run
else
    if ARGV[0].nil?
        puts "Need to provide directory"
    else
        puts "#{ARGV[0]} need to be a diretory"
    end
end
