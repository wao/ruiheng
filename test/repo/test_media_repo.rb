require 'test_helper.rb'

require 'storage'
require 'repo/media_repo'

class TestMediaRepo < Test::Unit::TestCase
    include TestNeedFileSystem

    def setup
        @base_path = setup_path( 'media_repo' )
    end

    def test_store
        repo_path = @base_path + "/test_store"
        assert( !File.exist?( repo_path ) )
        repo = Repo::Media.new( repo_path ) 
        assert( File.exist?( repo_path ) )

        jpg_path = repo_path + '/' + JPG_1_PATH
        file_id = Storage::Md5sum.new( JPG_1_MD5SUM )
        assert( !File.exist?( jpg_path ) )
        meta_data = {"name"=>'hello'}
        assert( !repo.exist?( file_id ) )
        repo.store_media( file_id, JPG_1 )
        repo.store_meta( file_id, meta_data )
        assert( repo.exist?( file_id ) )
        assert( File.exist?( jpg_path ) )
        assert( FileUtils.compare_file( jpg_path + "/media_data", JPG_1 ) )

        assert_equal meta_data, repo.get_media_meta( file_id )
    end
end

