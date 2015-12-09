#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../test_helper.rb"

require 'ruiheng/media_mgr'

require 'sequel-fixture'
require 'byebug'

include Ruiheng

class TestMediaMgr < Test::Unit::TestCase
    include TestNeedFileSystem

    def test_uuid_create
        @root_path = setup_path( "test_media_mgr1" )
        assert !File.exist?(@root_path + "/uuid")
        MediaMgr.new( @root_path )
        assert File.exist? @root_path + "/uuid" 
    end

    def test_uuid_load
        @root_path = setup_path( "test_media_mgr1" )
        assert !File.exist?(@root_path + "/uuid")
        uuid = Storage::Uuid.new
        File.write( @root_path + "/uuid", uuid.to_s )
        mgr = MediaMgr.new( @root_path )
        assert_equal uuid.uuid, mgr.uuid.uuid
    end

    def test_seq
        @root_path = setup_path( "test_next_seq" )
        mgr = MediaMgr.new( @root_path )
        assert_equal 1, mgr.seq
        mgr.inc_seq
        assert_equal 2, mgr.seq
        assert_equal 2, mgr.db.meta[1].seq
    end

    def test_add_tag
        @root_path = setup_path( "test_add_tag" )
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "..", "fixtures", "test_media_mgr" )
        mgr = Ruiheng::MediaMgr.new( @root_path )
        fixture = Sequel::Fixture.new :test_add_tag, mgr.db.db 
        assert_equal [ fixture.tags[0].id.to_s, fixture.tags[1].id.to_s ], mgr.media.db["1"].tags.map { |tag| tag.id }

        mgr.add_tag( [ mgr.media.db["1"] ], "tag1" )
        assert_equal [ fixture.tags[0].id.to_s, fixture.tags[1].id.to_s ], mgr.media.db["1"].tags.map { |tag| tag.id }


        assert_equal [], mgr.media.db["2"].tags.map { |tag| tag.id }
        mgr.add_tag( [ mgr.media.db["2"] ], "tag1" )
        assert_equal [ fixture.tags[0].id.to_s ], mgr.media.db["2"].tags.map { |tag| tag.id }
        mgr.add_tag( [ mgr.media.db["2"] ], "tag1" )
        assert_equal [ fixture.tags[0].id.to_s ], mgr.media.db["2"].tags.map { |tag| tag.id }
        mgr.add_tag( [ mgr.media.db["2"] ], "tag2" )
        assert_equal [ fixture.tags[0].id.to_s, fixture.tags[1].id.to_s ], mgr.media.db["2"].tags.map { |tag| tag.id }
        mgr.add_tag( [ mgr.media.db["2"] ], "tag3" )
        assert_equal [ fixture.tags[0].id.to_s, fixture.tags[1].id.to_s, mgr.tag.db[:text=>"tag3"].id ], mgr.media.db["2"].tags.map { |tag| tag.id }
    end

    def test_assign_tags
        @root_path = setup_path( "test_assign_tag" )
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "..", "fixtures", "test_media_mgr" )
        mgr = Ruiheng::MediaMgr.new( @root_path )
        fixture = Sequel::Fixture.new :test_add_tag, mgr.db.db 

        mgr.media.db["1"].tags = [ "1" ]

        assert_equal [ fixture.tags[0].id.to_s ], mgr.media.db["1"].tags.map { |tag| tag.id }
    end

    def test_split_media_list
        list = Array.new( 8, OpenStruct.new( :file_size=>1000000 ) );
        result = Ruiheng::MediaMgr.split_media_list_by_maxsize( list, [2000000] )
        assert_equal 8, result.length
        assert_equal 1000000, result[0][0].file_size

        result = Ruiheng::MediaMgr.split_media_list_by_maxsize( list, [3000000] )
        assert_equal 4, result.length
        assert_equal 1000000, result[0][0].file_size
        assert_equal 1000000, result[0][1].file_size

        result = Ruiheng::MediaMgr.split_media_list_by_maxsize( list, [4000000] )
        assert_equal 3, result.length
        assert_equal 2, result[2].length

        result = Ruiheng::MediaMgr.split_media_list_by_maxsize( list, [4000000,2000000] )
        assert_equal 6, result.length
        assert_equal 3, result[0].length
        assert_equal 1, result[1].length
        assert_equal 1, result[2].length
    end

    def recs_to_hash(recs)
        recs.map { |r| r.values.reject{ |k,v| [ :version, :modify_time ].include? k.to_sym } }.sort{ |a,b| a[:id] <=> b[:id] }
    end

    def compare_mgr( mgr, path, compare_media = false )
        assert File.exist? path
        backup_mgr = Ruiheng::MediaMgr.new( path )
        assert_equal recs_to_hash( mgr.tag.db.all ), recs_to_hash( backup_mgr.tag.db.all )
        assert_equal recs_to_hash( mgr.album.db.all ), recs_to_hash( backup_mgr.album.db.all )
        assert_equal recs_to_hash( mgr.checkin.db.all ), recs_to_hash( backup_mgr.checkin.db.all )
        assert mgr.media.db.first.tags.map { |t| t[:text] }.include? "tag4" 
        assert mgr.media.db.first.albums.map { |t| t[:name] }.include? "album4" 

        if compare_media 
            assert_equal recs_to_hash( mgr.media.db.all ), recs_to_hash( backup_mgr.media.db.all )
        end

        backup_mgr
    end


    def setup_backup_mgr( back_path )
        repo_path = setup_path( "test_backup" )
        mgr = Ruiheng::MediaMgr.new( repo_path )
        mgr.scan_and_import_media( sample_path )

        mgr.add_tag( [mgr.media.db.first], "tag1" )
        mgr.add_tag( [mgr.media.db.first], "tag2" )
        mgr.add_tag( [mgr.media.db.first], "tag3" )
        mgr.add_tag( mgr.media.db.all, "tag4" )
        mgr.add_album( mgr.media.db.all, "album4" )
        mgr.add_album( mgr.media.db.all, "album5" )
        mgr.add_album( mgr.media.db.all, "album6" )

        mgr
    end

    def test_backup
        mgr = setup_backup_mgr( "test_backup" )

        total_backup_path = setup_path( "test_backup_total" )
        mgr.backup_to_path( total_backup_path, 0, [2000000000] ) 

        compare_mgr( mgr, total_backup_path + "/0", true )

        multi_backup_path = setup_path( "test_backup_multi" )
        mgr_num = mgr.backup_to_path( multi_backup_path, 0, [2 * 1024 * 1024] ) 

        mgrs = []
        0.upto(mgr_num-1) do |i|
            mgrs << compare_mgr( mgr, multi_backup_path + "/" + i.to_s )
        end
        assert mgrs.length > 1
        assert_equal recs_to_hash( mgr.media.db.all ), mgrs.map { |mgr| recs_to_hash( mgr.media.db.all ) }.flatten.sort{ |a,b| a[:id] <=> b[:id] }
        mgrs.each_with_index do |mgr,i|
            assert ( mgr.calculate_backup_size(0) < 2 * 1024 * 1024 ) || ( mgr.media.db.all.length == 1 )
            assert_equal i, mgr.db.meta[1][:backup_seq]
        end
    end

    def test_backup_to_plan
        mgr = setup_backup_mgr( "test_backup_plan" )
        #total_backup_path = setup_path( "test_backup_plan_total" )
        plan = mgr.create_backup_plan( "backuplan1" )
        assert_equal "backuplan1", mgr.db.backup_plan[plan.id][:name]

        backup = mgr.backup_for_plan( plan.id, [2 * 1024 * 1024] ) 
        total_backup_path = mgr.root_path + "/media_backups/" + backup.id.to_s
        assert_equal backup.part_number, 5
        mgrs = []
        0.upto(backup.part_number-1) do |i|
            mgrs << compare_mgr( mgr, total_backup_path + "/" + i.to_s )
        end
        assert_equal recs_to_hash( mgr.media.db.all ), mgrs.map { |mgr| recs_to_hash( mgr.media.db.all ) }.flatten.sort{ |a,b| a[:id] <=> b[:id] }
        mgrs.each_with_index do |mgr,i|
            assert ( mgr.calculate_backup_size(0) < 2 * 1024 * 1024 ) || ( mgr.media.db.all.length == 1 )
            assert_equal i, mgr.db.meta[1][:backup_seq]
            assert_equal plan.id, mgr.db.meta[1][:backup_plan_uuid]
            assert_equal backup.id, mgr.db.meta[1][:backup_id]
        end
    end
end
