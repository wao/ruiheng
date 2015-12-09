require 'pathname'
require 'time'

module Ruiheng
    class DbRebuilder
        def initialize( mgr, checkin_root_path )
            @mgr = mgr
            @checkin_root_path = Pathname.new(checkin_root_path)
        end

        def rebuild
            scan_checkin
        end

        def scan_checkin
            @mgr.inc_seq
            self.class.scan_dir( @checkin_root_path, 5 ) do |path|
                @mgr.db.db.transaction do
                    id = Storage::Uuid.new( path.relative_path_from( @checkin_root_path ).to_s.gsub( '/', '-' ) )
                    meta = @mgr.checkin.repo.read_meta(id)
                    meta["id"] = meta["uuid"]
                    meta.delete "uuid" 
                    @mgr.db.checkin.create( meta )
                    @mgr.checkin.repo.read_list(id) do |fh|
                        fh.each_line do |line|
                            info = line.strip.split( ' |<>| ' )
                            if info[2] == 'y'
                                media_id = Storage::Md5sum.new(info[0])
                                media_meta = @mgr.media.repo.get_media_meta(media_id)
                                file_info = FileInfo.from_hash( media_meta )
                                @mgr.media.add( file_info.file_path, @mgr.seq, id, file_info ) 
                            end
                        end
                    end
                end
            end
        end


        def self.scan_dir( path, level, &block )
            scan_dir_internal( path, level, block )
        end

        def self.scan_dir_internal( path, level, block )
            if level == 0
                block.call( path )
            else
                Pathname.glob("#{path.to_s}/*") do |entry|
                    if entry.directory?
                        scan_dir_internal( entry, level - 1, block )
                    else
                        raise "Unexpect none directory file here #{entry}"
                    end
                end
            end
        end

        def import_checkin( mgr, path )
        end
    end
end
