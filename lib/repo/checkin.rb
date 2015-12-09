require 'storage'
require 'json'

module Repo
    #Store checkin information.
    #The repo is stored by uuid.
    class Checkin
        attr_reader :storage

        def initialize( root_path )
            @storage = Storage::Base.new( root_path )
        end

        def write_list(id)
            @storage.open( id, "list", "w" ) do |wr|
                yield wr
            end
        end

        def read_list(id)
            @storage.open( id, "list", "r" ) do |wr|
                yield wr
            end
        end

        def write_meta(id, meta)
            @storage.open( id, "meta.json", "w" ) do |wr|
                wr << meta.to_json
            end
        end


        def read_meta(id)
            @storage.open( id, "meta.json", "r" ) do |wr|
                JSON.load( wr.read )
            end
        end

        def exist?(id)
            @storage.exist?(id)
        end
        
        def copy_to_repo(id,dest_repo)
            @storage.copy_to_repo( id, dest_repo.storage )
            self
        end
    end
end
