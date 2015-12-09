#Repo module based on Storage module to provide clean interface for store/retrieve operation.

require 'handshake'
require 'storage'
require 'json'

#@TODO complete unit test and contract
module Repo
    #Store/Retrieve media data. use md5sum generated from media file as id. 
    #     media file store using name media_data
    #     meta file store as meta.json
    class Media
        include Handshake

        attr_reader :storage

        def initialize( root_path )
            @storage = Storage::Base.new( root_path )
        end

        contract [ Storage::Md5sum, String ] => anything
        before { | id, source_file | ( !@storage.exist?(id, "media_data") ) and File.exist? source_file }
        # Store media file and meta info into system.
        def store_media( id, source_file )
            #id = Storage::Md5sum.from_file( source_file )
            #@TODO need to consider power failure recovery: mark and retry
            @storage.store( source_file, id, "media_data" )
        end

        contract [ Storage::Md5sum, Hash ] => anything
        before { | id, meta_data |  !@storage.exist?(id, "meta.json" ) }
        def store_meta( id, meta_data )
            @storage.open( id, "meta.json", "w" ) do |wr|
                wr << meta_data.to_json
            end
        end

        def thumb_path( id )
            @storage.get_path_from_id( id, "thumb" )
        end

        def media_path( id )
            @storage.get_path_from_id( id, "media_data" )
        end

        def self.get_md5sum( source_file )
            Storage::Md5sum.from_file( source_file )
        end

        contract Storage::Md5sum => Hash
        def get_media_meta(md5sum)
            @storage.open(md5sum, "meta.json", "r" ) do |wr|
                JSON.load( wr.read )
            end
        end

        def copy(md5sum,dest)
            @storage.copy(md5sum, "media_data", dest)
            self
        end

        def copy_to_repo(md5sum,dest_repo)
            @storage.copy_to_repo( md5sum, dest_repo.storage )
            self
        end

        def open(md5sum)
            File.new( @storage.get_path_from_id( md5sum, "media_data" ), "r" )
        end

        contract [Storage::Md5sum, anything]=>anything
        def exist?(md5sum, subfilename="media_data")
            @storage.exist?( md5sum, subfilename )
        end
    end
end
