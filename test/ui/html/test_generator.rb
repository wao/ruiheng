#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../../test_helper.rb"
require 'ui/html/generator'
require 'ruiheng/media_mgr'

class TestHtmlGenerator < Test::Unit::TestCase
    include TestNeedFileSystem

    def dump(a)
        puts a
        a
    end

    def test_generate_sub_page
        root_path = setup_path( "test_html_generator" )
        mgr = Ruiheng::MediaMgr.new( root_path )

        checkin = mgr.scan_and_import_media( sample_path )
        generator = Ui::Html::Generator.new(mgr, root_path + "/www" )
        generator.fetch_nav_data
        assert !dump(generator.generate_sub_page( 2011, 9, 10)).empty?
        generator.generate
        assert File.exist? root_path + "/www/2011-09-10.html" 
    end
end
