require 'ruiheng/sync/items'
require 'null_console'

module Ruiheng
    class MediaMgr
        class Media
            include Sync::Items

            attr_reader :db, :repo, :console

            def initialize(mgr,db, repo, console=nil)
                @mgr = mgr
                @db = db
                @repo = repo
                @console = console || NullLogger.new
            end

            MediaExcludeFieldNames = Set.new [ :md5sum, :meta_version ]

            def check( path )
                file_info = Ruiheng::FileInfo.new( path ) if file_info.nil?
                if file_info.image? || file_info.video?
                    if !file_info.thumbnail?
                        if !repo.exist?( file_info.md5sum )
                            puts "[#{path}] is missed in repo"
                            false
                        else
                            if db[file_info.md5sum.to_s].nil?
                                puts "[#{path}] is missed in db"
                                false
                            else
                                true
                            end
                        end
                    else
                        false
                    end
                else
                    puts "[#{path}] is not media file"
                    false
                end
            end

            def add( path, seq = nil, checkin_id = nil, file_info = nil )
                seq = @mgr.seq if seq.nil?
                ret = :not_media
                checkin_id = file_info.checkin_id if ( checkin_id.nil? && file_info )
                file_info = Ruiheng::FileInfo.new( path ) if file_info.nil?
                if file_info.image? || file_info.video?
                    if file_info.thumbnail?
                        ret = :thumbnail
                    else
                        ret = :already_in_repo
                        if ! @repo.exist?( file_info.md5sum )
                            begin
                                #@TODO need to make sure opration atomic
                                #We only handle image file and video file
                                #TODO need to retrieve meta info here
                                @repo.store_media( file_info.md5sum, path )

                                file_info.write_thumb( @repo.thumb_path(file_info.md5sum) )
                                meta = file_info.to_hash
                                meta["checkin_id"] = checkin_id.to_s

                                #Store to repo
                                @repo.store_meta( file_info.md5sum, meta )
                                ret = :added_repo
                            rescue => ex
                                @repo.storage.move_to( file_info.md5sum, @mgr.get_gabage_path )
                                raise ex
                            end
                        end

                        if @mgr.db.media[file_info.md5sum.to_s].nil?
                            @mgr.db.db.transaction(:savepoint=>true) do
                                @mgr.db.media.create( dump( file_info.to_hash.merge( {:id=>file_info.md5sum, :checkin_id=>checkin_id, :version=>seq} ).reject { |field_name,field_value| MediaExcludeFieldNames.include? field_name.to_sym }  ) )
                            end
                            if ret != :added_repo
                                puts "add missed info in db"
                                ret = :added_db
                            else
                                ret = :added
                            end
                        end
                    end
                end
                return ret
            rescue => ex
                puts "add #{path} failed!"
                puts ex
                return :error
            end

            def dump(value)
                #puts value
                value
            end
        end
    end
end
