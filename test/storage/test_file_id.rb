#!/usr/bin/env ruby
require "test_helper.rb"
require "storage/file_id"

class TestStorageFileId < Test::Unit::TestCase
    include TestNeedFileSystem

    def test_md5sum
        assert_equal JPG_1_MD5SUM, Storage::Md5sum.from_file( JPG_1 ).to_s
        assert_equal JPG_1_PATH, Storage::Md5sum.from_file( JPG_1 ).to_path
    end

    def test_uuid
        content = "2345-121789-789"
        content_path = "2345/121789/789"
        uuid = Storage::Uuid.new( content )
        assert_equal content, uuid.to_s
        assert_equal content_path, uuid.to_path
    end
end
