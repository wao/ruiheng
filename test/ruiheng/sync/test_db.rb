#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../../test_helper.rb"

require 'sequel-fixture'
require 'ruiheng/media_mgr'

class TestSyncDb < Test::Unit::TestCase
    include TestNeedFileSystem

    def test_sync_tags
        local_path = setup_path( "test_sync_tags_local" )
        remote_path = setup_path( "test_sync_tags_remote" )

        local_mgr = Ruiheng::MediaMgr.new( local_path )
        remote_mgr = Ruiheng::MediaMgr.new( remote_path )

        local_mgr.media.add( JpgInfos[0].path )

        local_mgr.add_tag( [ local_mgr.media.db[JpgInfos[0].md5sum] ], "tag1" )
        local_mgr.add_tag( [ local_mgr.media.db[JpgInfos[0].md5sum] ], "tag2" )
        local_mgr.add_tag( [ local_mgr.media.db[JpgInfos[0].md5sum] ], "tag3" )

        local_mgr.sync( remote_mgr )

        assert_equal [ "tag1", "tag2", "tag3" ].sort, remote_mgr.media.db[JpgInfos[0].md5sum].tags.map{|i|i.text}.sort
        local_mgr.add_tag( [ local_mgr.media.db[JpgInfos[0].md5sum] ], "tag4" )
        local_mgr.media.db[JpgInfos[0].md5sum].remove_tag( local_mgr.tag.db[:text=>"tag1"] )
        assert_equal [ "tag2", "tag3", "tag4" ].sort, local_mgr.media.db[JpgInfos[0].md5sum].tags.map{|i|i.text}.sort

        
        remote_mgr.add_tag( [ remote_mgr.media.db[JpgInfos[0].md5sum] ], "tag5" )
        remote_mgr.media.db[JpgInfos[0].md5sum].remove_tag( remote_mgr.tag.db[:text=>"tag2"] )
        assert_equal [ "tag1", "tag3", "tag5" ].sort, remote_mgr.media.db[JpgInfos[0].md5sum].tags.map{|i|i.text}.sort

        local_mgr.sync( remote_mgr )
        assert_equal [ "tag3", "tag4", "tag5" ].sort, local_mgr.media.db[JpgInfos[0].md5sum].tags.map{|i|i.text}.sort
        assert_equal [ "tag3", "tag4", "tag5" ].sort, remote_mgr.media.db[JpgInfos[0].md5sum].tags.map{|i|i.text}.sort
    end
end
