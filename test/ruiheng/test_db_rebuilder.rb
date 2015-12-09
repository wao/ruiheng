#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/../test_helper.rb"

require 'fileutils'
require 'ruiheng/db_rebuilder'
require 'set'
require 'pathname'
require 'ruiheng/media_mgr'
require 'db'

class TestDbRebuilder < Test::Unit::TestCase
    include TestNeedFileSystem
    include FileUtils

    def test_scan_dir
        base_path = setup_path( 'test_scan' )

        dirs = [ 
            'test_scan/85f8c022/f218/41fe/8af6/21b1ceca5d25',
            'test_scan/85f8c022/f218/41fe/8af6/31b1ceca5d25',    
            'test_scan/85f8c022/f218/61fe/8af6/21b1ceca5d25',    
            'test_scan/85f8c022/f218/81fe/8af6/31b1ceca5d25',    
        ]

        dirs.each { |path| mkdir_p base_path + "/" + path }

        dir_set = Set.new dirs

        base_path = Pathname.new( base_path )

        Ruiheng::DbRebuilder.scan_dir( base_path.join( 'test_scan' ), 5  ) do |entry|
            path = Pathname.new(entry).relative_path_from( base_path ).to_s
            assert dir_set.include? path
            dir_set.delete(path)
        end

        assert dir_set.empty?, "should be empty"
    end

    def checkin_data( base_path )
        mgr = Ruiheng::MediaMgr.new( base_path )
        mgr.scan_and_import_media( sample_path )
    end

    ExcludeFieldSet = Set.new [ :version, :modify_time, :create_time, :time, :file_mod_time ]

    def rec_to_hash(rec)
        rec = rec.values.reject { |field_name, field_value| ExcludeFieldSet.include?( field_name.to_sym ) }
    end

    def assert_table_equal_internal( left, right )
        left.all.each do |left_rec|
            assert_equal rec_to_hash(left_rec), rec_to_hash( right[left_rec.id] )  
        end
    end

    def assert_table_equal( left, right )
        assert_table_equal_internal( left, right )
        assert_table_equal_internal( right, left )
    end

    def rebuild_db(base_path)
        mgr = Ruiheng::MediaMgr.new( base_path )
        mgr.rebuild_db
    end


    def test_rebuild
        assert_equal( {:a=>1}, {:a=>1} )
        base_path = setup_path( 'test_rebuild' )
        
        checkin_data( base_path )

        File.rename base_path + "/db/meta.db", base_path + "/db/meta.2.db"

        rebuild_db(base_path)

        mgr = Ruiheng::MediaMgr.new( base_path )

        old_db = Db::Db.new( "sqlite://" + base_path + "/db/meta.2.db", false )
        
        assert_table_equal( old_db.media, mgr.db.media )
        assert_table_equal( old_db.checkin, mgr.db.checkin )
    end
end
