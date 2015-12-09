require 'storage'
require 'ruiheng/file_info'
require 'db'
require 'find'

module Ruiheng
    #@TODO need to handle failure case: make sure all the data in disk is consistent. meta, media, list
    class MediaScan
        attr_reader :uuid, :a_unhandled_items, :meta, :added_count, :not_media_count, :already_in_repo_count, :total_count, :thumbnail_count, :added_db_count, :added_repo_count, :error_count, :error_items

        def initialize( media_mgr, uuid = nil )
            @media_mgr = media_mgr
            @uuid = Storage::Uuid.new( uuid )
            @a_unhandled_items = []
            @added_count = 0
            @added_db_count = 0
            @added_repo_count = 0
            @not_media_count = 0
            @already_in_repo_count = 0
            @total_count = 0
            @error_count = 0
            @thumbnail_count = 0
            @error_items = []
        end


        def check_create_time( src_path )
            ret = true
            count = 0
            puts "scan for null create_time file."
            #puts "Scan dir #{src_path}"
            Find.find( src_path ) do |entry|
                if File.file?( entry )
                    file_info = Ruiheng::FileInfo.new( entry )
                    if ( file_info.image? || file_info.video? ) && file_info.create_time.nil?
                        puts "File #{file_info.file_path} can't detect create time. Make: #{file_info.make}, Model: #{file_info.model}"
                        ret = false
                    end
                    count += 1
                    if count % 100 == 0
                        puts "scan #{count} files."
                    end
                end
            end
                        
            ret
        end

        def scan( src_path )
            #if !check_create_time( src_path )
                #raise 'Have files without create_time!'
            #end
            @time = Time.now.utc
            @seq = @media_mgr.inc_seq
            @media_mgr.db.db.transaction do 
                begin
                    @media_mgr.checkin.repo.write_list(@uuid) do | file_list |
                        scan_dir( src_path, file_list )
                    end
                rescue => ex
                    puts "Error [%s] happened in #s, %s" % [ ex, __FILE__, __LINE__ ]
                    puts ex.backtrace.join("\n")
                end

                @meta = { :src_path=>File.absolute_path(src_path), :total_count=>@total_count, :added_count=>@added_count, :added_db_count=>@added_db_count, :added_repo_count=>@added_repo_count, :thumbnail_count=>@thumbnail_count, :not_media_count=>@not_media_count, :already_in_repo_count=>@already_in_repo_count, :time=>@time, :uuid=>@uuid, :version=>@seq, :error_count=>@error_count, :error_items=>@error_items } 

                @media_mgr.checkin.repo.write_meta( @uuid, @meta )

                @media_mgr.db.checkin.create({ :src_path=>File.absolute_path(src_path), :error_count=>@error_count, :thumbnail_count=>@thumbnail_count, :total_count=>@total_count, :added_count=>@added_count,  :not_media_count=>@not_media_count, :already_in_repo_count=>@already_in_repo_count, :time=>@time, :id=>@uuid, :version=>@seq })
            end

            OpenStruct.new(@meta.merge(:id=>@uuid))
        end

        #@TODO handle exception here
        def scan_dir( src_path, file_list )
            #puts "Scan dir #{src_path}"
            Find.find( src_path ) do |entry|
                if File.file?( entry )
                    @total_count += 1
                    file_info = Ruiheng::FileInfo.new( entry )
                    case @media_mgr.media.add( entry, @seq, @uuid, file_info )
                    when :added
                        puts "#{@total_count}:added: #{entry}"
                        file_list.puts "%s |<>| %s |<>| y" % [ file_info.md5sum.to_s, entry ]
                        @added_count += 1

                    when :added_db
                        puts "#{@total_count}:added: #{entry}"
                        file_list.puts "%s |<>| %s |<>| d" % [ file_info.md5sum.to_s, entry ]
                        @added_db_count += 1

                    when :added_repo
                        puts "#{@total_count}:added: #{entry}"
                        file_list.puts "%s |<>| %s |<>| r" % [ file_info.md5sum.to_s, entry ]
                        @added_repo_count += 1

                    when :not_media
                        puts "#{@total_count}:reject: not media: #{entry}"
                        file_list.puts "%s |<>| %s |<>| i" % [ file_info.md5sum.to_s, entry ]
                        @a_unhandled_items << entry
                        @not_media_count += 1

                    when :already_in_repo
                        puts "#{@total_count}:reject: already: #{entry}"
                        file_list.puts "%s |<>| %s |<>| a" % [ file_info.md5sum.to_s, entry ]
                        @already_in_repo_count += 1
                    when :thumbnail
                        puts "#{@total_count}:reject: thumbnail: #{entry}"
                        file_list.puts "%s |<>| %s |<>| t" % [ file_info.md5sum.to_s, entry ]
                        @thumbnail_count += 1
                    when :error
                        puts "#{@total_count}:failed: error: #{entry}"
                        file_list.puts "%s |<>| %s |<>| e" % [ file_info.md5sum.to_s, entry ]
                        @error_count += 1
                        @error_items << entry
                    else
                        raise 'Unknown error!'
                    end
                end
            end
        end
    end
end
