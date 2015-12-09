require 'test_helper.rb'

require 'ruiheng/media_mgr'
require 'ruiheng/media_scan'

require 'db'

class TestMediaScan < Test::Unit::TestCase
    include TestNeedFileSystem

    def setup
        @repo_path = setup_path( "test_checkin" )
        @mgr = Ruiheng::MediaMgr.new( @repo_path )
    end

    def test_basic
       seq = @mgr.seq
       checkin = @mgr.scan_and_import_media( sample_path )
       assert( @mgr.checkin.repo.exist?( checkin.uuid ) )
       assert( @mgr.media.repo.exist?( Storage::Md5sum.new( JPG_1_MD5SUM ) ) )
       assert_equal 8, checkin.meta[:total_count]
       assert_equal 6, checkin.meta[:added_count]
       assert_equal 2, checkin.meta[:not_media_count]
       assert_equal 0, checkin.meta[:already_in_repo_count]
       assert_equal seq+1, @mgr.db.checkin[checkin.uuid.to_s][:version]
       #puts @mgr.repo_media.get_media_meta( Storage::Md5sum.new( JPG_1_MD5SUM ) )
       assert_equal JPG_1_MODEL, @mgr.db.media[JPG_1_MD5SUM][:model]
       assert_equal JPG_1_MAKE, @mgr.db.media[JPG_1_MD5SUM][:make]
       assert_equal JPG_1_SIZE, @mgr.db.media[JPG_1_MD5SUM][:file_size]
       assert_equal seq+1, @mgr.db.media[JPG_1_MD5SUM][:version]

       assert( @mgr.media.repo.exist?( Storage::Md5sum.new( MP4_1_MD5SUM ) ) )
       assert File.exist? @repo_path + "/media/" + MP4_1_PATH + "/thumb"
    end

    def test_scan_bad
        repo_path = setup_path( "test_scan_bad" )
        mgr = Ruiheng::MediaMgr.new( @repo_path )
        checkin = @mgr.scan_and_import_media( sample_bad_path )
        assert_equal 5, checkin.meta[:total_count]
        assert_equal 1, checkin.meta[:added_count]
        assert_equal 4, checkin.meta[:error_count]
        assert( @mgr.checkin.repo.exist?( checkin.uuid ) )
        assert( @mgr.media.repo.exist?( Storage::Md5sum.new( JPG_1_MD5SUM ) ) )

        assert_equal [ JPG_1_MD5SUM ], @mgr.media.db.select_map( :id )
    end
end
