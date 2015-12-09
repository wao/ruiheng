#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/test_helper.rb"

require 'db'
require 'set'

class TestDb < Test::Unit::TestCase
    include TestNeedFileSystem

    SYNC_DATA = [
        { :left_uuid => "left_uuid", :left_version => 17, :right_uuid => "right_uuid", :right_version => 30 },
        { :left_uuid => "left_uuid22222", :left_version => 897, :right_uuid => "right_uuid2222222222", :right_version => 190 }
    ]


    SYNC_DATA_DIFF = { :left_uuid => "left_uuid", :left_version => 33, :right_uuid => "right_uuid", :right_version => 90 }

    SYNC_DATA2 = [
        SYNC_DATA_DIFF,
        { :left_uuid => "left_uuid22222", :left_version => 897, :right_uuid => "right_uuid2222222222", :right_version => 190 }
    ]

    SYNC_DATA3 = [
        { :left_uuid => "left_uuid", :left_version => 17, :right_uuid => "right_uuid", :right_version => 30 },
        { :left_uuid => "left_uuid", :left_version => 27, :right_uuid => "right_uuid", :right_version => 39 },
        { :left_uuid => "left_uuid", :left_version => 37, :right_uuid => "right_uuid", :right_version => 19 },
    ]


    SYNC_DATA4 = [
        { :left_uuid => "left_uuid", :left_version => 17, :right_uuid => "right_uuid", :right_version => 30 },
        { :left_uuid => "left_uuid", :left_version => 27, :right_uuid => "right_uuid", :right_version => 39 },
        { :left_uuid => "right_uuid", :left_version => 7, :right_uuid => "left_uuid", :right_version => 49 },
        { :left_uuid => "right_uuid", :left_version => 17, :right_uuid => "left_uuid", :right_version => 47 },
        { :left_uuid => "left_uuid", :left_version => 37, :right_uuid => "right_uuid", :right_version => 19 },
    ]
    def setup
        base_path = setup_path( 'db_sync' )
        @base_path = "sqlite://" + base_path
    end

    def load_db( name, initial_data )
        db = Db::Db.new( @base_path + "/" + name, true )
        initial_data.each do |data|
            db.sync.create( data )
        end

        db
    end

    def gen_id(data)
        Storage::Md5sum.from_string( "%s:%d:%s:%d" % [ data[:left_uuid], data[:left_version], data[:right_uuid], data[:right_version] ] ).to_s
    end

    def assert_datas_equal_db( datas, db )
        ids = datas.inject( Set.new ) do |id_set, data|
            data_id = gen_id(data)
            assert_equal data_id, db.sync.where( data ).first.id
            id_set << data_id
        end

        assert_equal datas.length, db.sync.all.length
        assert_equal ids, db.sync.ids
    end

    def test_sync
        db = load_db( "meta.db", SYNC_DATA )

        assert_datas_equal_db( SYNC_DATA, db )
    end

    def test_sync_sync_one_db_is_empty
        left = load_db( "meta.db", SYNC_DATA2 )
        right = load_db( "meta2.db", [])
        right2 = load_db( "meta3.db", [])

        assert_datas_equal_db( SYNC_DATA2, left )
        assert_datas_equal_db( [], right )
        assert_datas_equal_db( [], right2 )

        left.sync.sync( right.sync )

        assert_datas_equal_db( SYNC_DATA2, left )
        assert_datas_equal_db( SYNC_DATA2, right )

        right2.sync.sync(left.sync)
        assert_datas_equal_db( SYNC_DATA2, left )
        assert_datas_equal_db( SYNC_DATA2, right2 )
    end

    def test_sync_sync_both_have_data
        left = load_db( "meta.db", SYNC_DATA2 )
        right = load_db( "meta2.db", SYNC_DATA)

        assert_datas_equal_db( SYNC_DATA2, left )
        assert_datas_equal_db( SYNC_DATA, right )

        left.sync.sync(right.sync)

        sync_datas = SYNC_DATA << SYNC_DATA_DIFF
        assert_datas_equal_db( sync_datas, left )
        assert_datas_equal_db( sync_datas, right )
    end

    def test_sync_get_version_info_left_or_right_only
        db = load_db( "meta.db", SYNC_DATA3 )
        version_info = db.sync.get_version_info( "left_uuid", "right_uuid" )
        assert_equal 37, version_info[:left_version]
        assert_equal 19, version_info[:right_version]

        version_info = db.sync.get_version_info( "right_uuid", "left_uuid" )
        assert_equal 39, version_info[:left_version]
        assert_equal 27, version_info[:right_version]

        version_info = db.sync.get_version_info( "right_uuid1", "left_uuid" )
        assert_equal 0, version_info[:left_version]
        assert_equal 0, version_info[:right_version]
    end

    def test_sync_get_version_info_left_and_right_both_have_data
        db = load_db( "meta.db", SYNC_DATA4 )
        version_info = db.sync.get_version_info( "left_uuid", "right_uuid" )
        assert_equal 49, version_info[:left_version]
        assert_equal 7, version_info[:right_version]

        version_info = db.sync.get_version_info( "right_uuid", "left_uuid" )
        assert_equal 39, version_info[:left_version]
        assert_equal 27, version_info[:right_version]
    end

    def test_tag_media_relations
        db_path = setup_path( 'test_db_1' )
        db1 = Db::Db.new( "sqlite://" + db_path + "/1.db", true )
        db2 = Db::Db.new( "sqlite://" + db_path + "/2.db", true )

        db1.media.create( :id=>"mediaid1"  );
        db2.media.create( :id=>"mediaid2"  );

        db1.media["mediaid1"].add_tag( :id=>"tagid1", :text=>"medida1tag" );
        db2.media["mediaid2"].add_tag( :id=>"tagid3", :text=>"medida1tag" );


        assert_equal db1.media["mediaid1"].tags[0][:id], "tagid1"
        assert_equal db2.media["mediaid2"].tags[0][:id], "tagid3"
    end

    def test_patcamera

    end
end
