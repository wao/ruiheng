# @author yangchen@thinkmore.info
# Reponsibility:
#     Read/Write/Test file or path by id
#
#     id is provide by external
#
#Design Note:
#     A repo consists following parts:
#        1, root path
#        2, manager target: file or path
#        3, map relation id<-->path ( this should belong to id, but last component is file or path depends on repo )
#        4, the method of generating id: internal caculated or external provided
#
#   2 and 4 affect API.
#
#   However, as I carefully consider, the only api I need is path. The storage module only need to manager path and provide facility to help safely deal withe sub files. Upper layer can use this kind api to provide a clean final api.
#

require 'handshake'
require 'fileutils'

require 'storage/file_id'

module Storage
    class Base
        include Handshake

        attr_reader :root_path

        contract String=>anything
        after{ |root_path| File.directory?( root_path ) }
        def initialize( root_path )
            if( !File.exist?( root_path ) )
                FileUtils.mkdir_p( root_path )
            else
                if( !File.directory?( root_path ) )
                    raise 'Storage root path %s must be a directory' % @root_path
                end
            end
            @root_path = root_path
        end

        class << self
            def id?
                clause{ |id| id.respond_to? :to_path }
            end

            def nil_or_string
                clause{ |id| id.nil? or id.is_a? String }
            end
        end

        contract [id?, nil_or_string] => anything
        def exist?(id,subfilename=nil)
            File.exist?( get_path_from_id( id, subfilename ) )
        end

        contract [id?, nil_or_string] => String
        def get_path_from_id(id, subfilename = nil)
            if( subfilename )
                File.join( @root_path, path_from_id(id), subfilename )
            else
                File.join( @root_path, path_from_id(id) )
            end
        end

        contract [String, id?, String] => self
        before{ |source, id, subfilename| (!File.exist? get_path_from_id( id, subfilename )) and ( File.exist? source ) }
        after{ |source, id, subfilename,ret| File.exist? get_path_from_id( id, subfilename ) }
        def store(source,id,subfilename)
            file_path = get_path_from_id( id, subfilename ) 
            ensure_parent_path( file_path )
            FileUtils.copy_file( source, file_path )
            self
        end

        contract [id?, String, String] => self
        before{ |id, subfilename, dest| File.exist?( get_path_from_id( id, subfilename ) ) and (!File.exist? dest ) }
        after{ |id, subfilename, dest, ret| File.exist? dest }
        def copy( id, subfilename, dest )
            FileUtils.cp( get_path_from_id( id, subfilename ), dest )
            self
        end

        def copy_to_repo( id, dest_repo )
           src_path = get_path_from_id(id) 
           dest_path = dest_repo.get_path_from_id(id)
           FileUtils.mkdir_p dest_path
           Dir[src_path+"/*"].each do |file|
               FileUtils.cp( file, dest_path )
           end
        end

        #Warnning: this call will move dirtory to other place, may cause data lose.
        def move_to( id, dest )
           src_path = get_path_from_id(id) 
           raise "#{dest} is not a valid path" if ( (File.exist? dest) && (!File.directory? File.dirname( dest )) ) || ( !File.directory? dest )
           FileUtils.mv src_path, dest
        end

        contract [id?, String, String, Block(anything=>anything) ] => anything
        #@TODO check mode, before/after
        def open( id, subfilename, mode )
            file_path = get_path_from_id( id, subfilename ) 
            ensure_parent_path( file_path )
            File.open( file_path, mode ) do |wr|
                yield wr
            end
        end

        contract [id?, String] => self
        before{ |id, subfilename| File.exist? get_path_from_id( id, subfilename ) }
        after{ |id, subfilename, ret| ! File.exist? get_path_from_id( id, subfilename ) }
        def remove( id, subfilename )
            FileUtils.remove( get_path_from_id( id, subfilename ) )
            self
        end

        private 

        def ensure_parent_path(file_path)
            if ! File.exist? File.dirname file_path 
                FileUtils.mkdir_p File.dirname file_path
            end
        end

        #Get relative path from id.
        #  Subclass can override to provide file like api.
        def path_from_id(id)
            id.to_path
        end
    end
end
