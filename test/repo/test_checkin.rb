require 'test_helper.rb'

require 'repo/checkin'


class TestRepoCheckin < Test::Unit::TestCase
    include TestNeedFileSystem

    def setup
        @base_path = setup_path( 'media_repo' )
    end

    def test_store
        repo_path = @base_path + "/test_store"
        assert( !File.exist?( repo_path ) )
        repo = Repo::Checkin.new( repo_path ) 
        assert( File.exist?( repo_path ) )

        uuid = Storage::Uuid.new( "aaa-bbb-cccccc" )

        a_lines = [ "line 1", "line 2" ]
        repo.write_list( uuid ) do |wr|
            a_lines.each do |line|
                wr.puts line 
            end
        end

        assert( File.exist?( repo_path + "/aaa/bbb/cccccc" ) )
        a_info = []
        repo.read_list( uuid ) { |wr| a_info = wr.readlines.map{ |line| line.chop } }
        assert_equal a_lines, a_info

        meta = { "time"=>2014 }

        repo.write_meta( uuid, meta )

        assert_equal meta, repo.read_meta( uuid )
    end
end
