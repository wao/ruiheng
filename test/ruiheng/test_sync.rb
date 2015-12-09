#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../test_helper.rb"

require 'ruiheng/media_mgr'
include Ruiheng

class TestSync < Test::Unit::TestCase
    include TestNeedFileSystem

    def assert_media_not_exist( media_info, mgr )
        assert ! File.exist?(mgr.media.repo.storage.root_path + "/" + media_info.id_path), "media with id as #{media_info.md5sum} should not exist!"
        assert ! File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path + "/media_data")
        assert ! File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path +  "/thumb")
        assert ! File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path +  "/meta.json")

        assert mgr.db.media[media_info.md5sum].nil?
    end

    def assert_media_exist( media_info, mgr )
        assert File.exist?(mgr.media.repo.storage.root_path + "/" + media_info.id_path)
        assert File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path + "/media_data")
        assert File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path +  "/thumb")
        assert File.exist?(mgr.media.repo.storage.root_path +  "/" + media_info.id_path +  "/meta.json")
        assert FileUtils.compare_file(mgr.media.repo.storage.root_path +  "/" + media_info.id_path + "/media_data", media_info.path ) 

        assert !mgr.db.media[media_info.md5sum].nil?
    end

    def assert_medias_exist( media_infos, mgr )
        media_infos.each do |media|
            assert_media_exist( media, mgr )
        end
    end

    def assert_medias_not_exist( media_infos, mgr )
        media_infos.each do |media|
            assert_media_not_exist( media, mgr )
        end
    end



    def setup
        @left_path = setup_path( "test_diff_and_sync_left" )
        @right_path = setup_path( "test_diff_and_sync_right" )

        @left_mgr = MediaMgr.new @left_path
        @right_mgr = MediaMgr.new @right_path
    end

    def apply_patch( local, patch, remote, local_seq )
        local.media.apply_patch( patch, remote.media, local_seq  )
    end

    def test_media_diff_and_apply_patch
        @left_mgr.inc_seq
        left_version_0 = @left_mgr.seq

        @left_mgr.inc_seq
        left_version_1 = @left_mgr.seq

        @left_mgr.media.add( JpgInfos[0].path, left_version_1 )

        left_version_2 = @left_mgr.inc_seq

        left_version_3 = @left_mgr.inc_seq
        @left_mgr.media.add( JpgInfos[1].path, left_version_3 )
        @left_mgr.media.add( JpgInfos[2].path, left_version_3 )

        diff0 = @left_mgr.media.diff( left_version_0, left_version_1 )
        assert_equal Set.new( [JpgInfos[0].md5sum] ), diff0


        diff1 = @left_mgr.media.diff( left_version_1+1, left_version_2 )
        assert_equal Set.new( [] ), diff1

        diff2 = @left_mgr.media.diff( left_version_2+1, left_version_3 )
        assert_equal Set.new( [JpgInfos[1].md5sum, JpgInfos[2].md5sum] ), diff2

        diff3 = @left_mgr.media.diff( left_version_0, left_version_3 )
        assert_equal Set.new( [JpgInfos[0].md5sum, JpgInfos[1].md5sum, JpgInfos[2].md5sum] ), diff3

        assert_medias_not_exist( JpgInfos, @right_mgr )

        apply_patch( @right_mgr, diff0, @left_mgr, @right_mgr.inc_seq )

        assert_medias_exist( JpgInfos.slice(0,1), @right_mgr )
        assert_medias_not_exist( JpgInfos.slice(1,2), @right_mgr )

        apply_patch( @right_mgr, diff2, @left_mgr, @right_mgr.inc_seq )
        assert_medias_exist( JpgInfos.slice(0,3), @right_mgr )
        assert_medias_not_exist( JpgInfos.slice(3,1), @right_mgr )
    end

    def modify_media(mgr, id, values)
        values[:version] = mgr.seq
        mgr.db.media[id].update(values)
    end

    def modify_conflict_1( mgr, id)
        modify_media( mgr, id, {:model=>'hh', :make=>'bc'})
    end

    def modify_conflict_2( mgr, id )
        modify_media( mgr, id, {:mime=>"sgml", :model=>'xx'})
    end

    def test_resolve_conflicts
        left_version_0 = @left_mgr.inc_seq
        right_version_0 = @right_mgr.inc_seq
        @left_mgr.media.add( JpgInfos[0].path  )
        @right_mgr.media.add( JpgInfos[0].path )

        @left_mgr.backup_db
        @right_mgr.backup_db

        @left_mgr.inc_seq
        @right_mgr.inc_seq

        modify_conflict_2( @left_mgr, JpgInfos[0].md5sum )
        modify_conflict_1( @right_mgr, JpgInfos[0].md5sum )

        left_version_2 = @left_mgr.inc_seq
        right_version_2 = @right_mgr.inc_seq

        conflicts = Set.new( [JpgInfos[0].md5sum] )

        @left_mgr.db.media.resolve_conflicts( conflicts, @left_mgr.load_backup_db(left_version_0).media, left_version_2, @right_mgr.db.media, @right_mgr.load_backup_db(right_version_0).media, right_version_2 ) 


        recs = [
            @left_mgr.db.media[JpgInfos[0].md5sum],
            @right_mgr.db.media[JpgInfos[0].md5sum]
        ]
        
        recs.each do |rec|
            assert_equal 'sgml', rec[:mime]
            assert_equal 'hh', rec[:model]
            assert_equal 'bc', rec[:make]
        end

        assert_equal left_version_2, recs[0][:version]
        assert_equal right_version_2, recs[1][:version]
    end


    def test_resolve_conflicts_reverse_datetime
        left_version_0 = @left_mgr.inc_seq
        right_version_0 = @right_mgr.inc_seq
        @left_mgr.media.add( JpgInfos[0].path  )
        @right_mgr.media.add( JpgInfos[0].path )

        @left_mgr.backup_db
        @right_mgr.backup_db

        @left_mgr.inc_seq
        @right_mgr.inc_seq


        modify_conflict_1( @right_mgr, JpgInfos[0].md5sum )
        modify_conflict_2( @left_mgr, JpgInfos[0].md5sum )

        left_version_2 = @left_mgr.inc_seq
        right_version_2 = @right_mgr.inc_seq

        conflicts = Set.new( [JpgInfos[0].md5sum] )

        @left_mgr.db.media.resolve_conflicts( conflicts, @left_mgr.load_backup_db(left_version_0).media, left_version_2, @right_mgr.db.media, @right_mgr.load_backup_db(right_version_0).media, right_version_2 ) 


        recs = [
            @left_mgr.db.media[JpgInfos[0].md5sum],
            @right_mgr.db.media[JpgInfos[0].md5sum]
        ]
        
        recs.each do |rec|
            assert_equal 'sgml', rec[:mime]
            assert_equal 'xx', rec[:model]
            assert_equal 'bc', rec[:make]
        end

        assert_equal left_version_2, recs[0][:version]
        assert_equal right_version_2, recs[1][:version]
    end

    def assert_sync_exist( mgr, left_uuid, left_version, right_uuid, right_version )
        assert !mgr.db.sync[ :left_uuid=>left_uuid.to_s, :left_version=>left_version, :right_uuid=>right_uuid.to_s, :right_version=>right_version].nil?
    end


    def test_one_way_sync
        @left_mgr.media.add( JpgInfos[0].path )

        assert_media_not_exist( JpgInfos[0], @right_mgr )
        @left_mgr.sync( @right_mgr )
        assert_media_exist( JpgInfos[0], @right_mgr )


        @left_mgr.media.add( JpgInfos[1].path )
        assert_media_not_exist( JpgInfos[1], @right_mgr )
        @left_mgr.sync( @right_mgr )
        assert_medias_exist( JpgInfos.slice(0,2), @right_mgr )

        assert_sync_exist( @left_mgr, @left_mgr.uuid, @left_mgr.seq - 1, @right_mgr.uuid, @right_mgr.seq - 1 )
        assert_sync_exist( @right_mgr, @left_mgr.uuid, @left_mgr.seq - 1, @right_mgr.uuid, @right_mgr.seq - 1 )
    end

    def test_two_way_sync
        @left_mgr.media.add( JpgInfos[0].path )
        @left_mgr.media.add( JpgInfos[1].path )

        @right_mgr.media.add( JpgInfos[2].path )

        @left_mgr.sync( @right_mgr )

        assert_medias_exist( JpgInfos.slice(0,3), @left_mgr )
        assert_medias_exist( JpgInfos.slice(0,3), @right_mgr )
        assert_sync_exist( @left_mgr, @left_mgr.uuid, @left_mgr.seq - 1, @right_mgr.uuid, @right_mgr.seq - 1 )
        assert_sync_exist( @right_mgr, @left_mgr.uuid, @left_mgr.seq - 1, @right_mgr.uuid, @right_mgr.seq - 1 )

        #introduce conflicts
        modify_conflict_1( @right_mgr, JpgInfos[0].md5sum )
        modify_conflict_2( @left_mgr, JpgInfos[0].md5sum )

        @right_mgr.media.add( JpgInfos[3].path )
        @left_mgr.sync( @right_mgr )
        assert_medias_exist( JpgInfos.slice(0,4), @left_mgr )
        assert_medias_exist( JpgInfos.slice(0,4), @right_mgr )

        recs = [
            @left_mgr.db.media[JpgInfos[0].md5sum],
            @right_mgr.db.media[JpgInfos[0].md5sum]
        ]
        
        recs.each do |rec|
            assert_equal 'sgml', rec[:mime]
            assert_equal 'xx', rec[:model]
            assert_equal 'bc', rec[:make]
        end
    end


    def test_backup
        left_version_base = @left_mgr.seq
        @left_mgr.db.db.transaction do
            @left_mgr.media.add( JpgInfos[0].path )
            @left_mgr.media.add( JpgInfos[1].path )
        end

        left_version_0 = @left_mgr.inc_seq

        backup_path_0 = setup_path( "test_backup_0" )
        @left_mgr.old_backup_to_path( backup_path_0, 0 )

        backup0_mgr = Ruiheng::MediaMgr.new( backup_path_0 )
        assert_medias_exist( JpgInfos.slice(0,2), backup0_mgr )
        assert_medias_not_exist( JpgInfos.slice(2,2), backup0_mgr )

        left_version_1 = @left_mgr.inc_seq

        @left_mgr.db.db.transaction do
            @left_mgr.media.add( JpgInfos[2].path )
        end

        backup_path_1 = setup_path( "test_backup_1" )
        @left_mgr.old_backup_to_path( backup_path_1, left_version_0+1 )
        backup1_mgr = Ruiheng::MediaMgr.new( backup_path_1 )
        assert_medias_not_exist( JpgInfos.slice(0,2), backup1_mgr )
        assert_medias_exist( JpgInfos.slice(2,1), backup1_mgr )
        assert_medias_not_exist( JpgInfos.slice(3,1), backup1_mgr )

        assert_equal JpgInfos.slice(0,2).inject(0) { |sum,item| sum + File.size( item.path ) }, @left_mgr.calculate_backup_size( 0, left_version_0 )
        assert_equal JpgInfos.slice(2,1).inject(0) { |sum,item| sum + File.size( item.path ) }, @left_mgr.calculate_backup_size( left_version_0 + 1 )

        sizes =@left_mgr.calculate_version_sizes( 0, left_version_1 + 1 )

        assert_equal JpgInfos.slice(0,2).inject(0) { |sum,item| sum + File.size( item.path ) }, sizes[left_version_base]
        assert_equal JpgInfos.slice(2,1).inject(0) { |sum,item| sum + File.size( item.path ) }, sizes[left_version_1]
    end
end
