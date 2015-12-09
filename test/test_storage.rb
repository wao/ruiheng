#!/usr/bin/env ruby
require "test_helper.rb"
require "storage"

class TestStorage < Test::Unit::TestCase
    include TestNeedFileSystem

    class DummyId
        def initialize(path)
            @path = path
        end

        def to_path
            @path
        end
    end

    def setup
        @base_path = setup_path( 'simple_repo' )
    end

    def test_store
        repo_path = @base_path + "/test_store"
        assert( !File.exist?( repo_path ) )
        repo = Storage::Base.new( repo_path ) 
        assert( File.exist?( repo_path ) )

        id = DummyId.new( '1/2/3' )
        assert( !repo.exist?( id ) )
        src_file_path = sample_path + '1.jpg'
        assert( !repo.exist?( id , "pcdata" ) )
        repo.store( src_file_path, id, "pcdata" )
        assert( repo.exist?(id, "pcdata") )
        assert( File.exist?( repo.get_path_from_id( id, "pcdata" ) ) )
        assert( FileUtils.compare_file( repo.get_path_from_id( id, "pcdata" ), src_file_path ) )

        #@todo need to change Error
        #assert_raise( RuntimeError ){
        #    repo.store( DummyId.new( '1/2/3' ), src_file_path )
        #}

        repo.remove( id, "pcdata" )
        assert( !File.exist?( repo.get_path_from_id( id, "pcdata" ) ) )
    end

    def test_write
        repo_path = @base_path + "/test_write"
        repo = Storage::Base.new( repo_path ) 
        id1 = DummyId.new( '1/2/4' )
        id2 = DummyId.new( '1/2/5' )
        assert( !repo.exist?( id1 ) )
        #content1 = "abcdef"
        content2 = "xxxxyyyyydef"
        #repo.write_to( id1, content1 )
        #assert_equal( content1, File.open(repo.file_path_from_id(id1)).read )
        repo.open( id2, 'meta', 'w' ) do |wr|
            wr << content2
        end
        assert_equal( content2, File.open(repo.get_path_from_id(id2, 'meta')).read )

        #@todo need to change Error
        #assert_raise( RuntimeError ){
        #    repo.write_to( id1, content1 )
        #}

        assert( repo.exist?( id2 ) )
        FileUtils.mkdir_p repo_path + "/gabage"
        repo.move_to( id2, repo_path + "/gabage" )
        assert( !repo.exist?( id2 ) )
        assert( File.exist? repo_path + "/gabage/5" )
        assert( File.exist? repo_path + "/gabage/5/meta" )
    end
end
