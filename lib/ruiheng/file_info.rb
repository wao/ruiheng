require 'RMagick'
require 'mini_exiftool'
require 'mimemagic'
require 'byebug'

#@TODO need add contract and unit test
module Ruiheng
    class FileInfo
        META_VERSION = 0.1

        attr_reader :file_path, :file_mod_time

        def initialize(file_path,attr={})
            # @todo need to specify error type
            raise "#{file_path} is not a regular file or not exists!" if ! File.file?(file_path) 
            @file_path = file_path
            @file_mod_time = attr["file_mod_time"].nil? ? File.mtime( file_path ) : attr["file_mod_time"]
            @md5sum = attr["md5sum"]
            @mime = attr["mime"] 
            @exif_tool = nil
            @create_time = attr["create_time"]
            @create_time_source = attr["create_time_source"]
        end

        def exif
            if @exif_tool.nil?
                begin
                    @exif_tool = MiniExiftool.new( file_path )
                    if @exif_tool.Error.nil?
                        @exif = @exif_tool
                    end
                rescue => ex
                    puts "Initialize ex error for #{file_path}"
                    raise ex
                end
            end
            @exif
        end

        def make
            if @exif
                @exif['make']
            else
                nil
            end
        end

        def model
            if @exif
                @exif['model']
            else 
                nil
            end
        end

        def create_time
            if @create_time.nil? 
                detect_create_time
            end
            @create_time
        end

        def create_time_source
            if @create_time.nil? 
                detect_create_time
            end
            @create_time_source
        end

        CREATE_TIME_FROM_TAG = 1
        CREATE_TIME_FROM_NAME = 2
        CREATE_TIME_FROM_MODIFY_TIME = 3
        CREATE_TIME_FROM_USER = 4

        CreateTimePattern = [
            /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})_(?<hour>\d{2})-(?<min>\d{2})-(?<second>\d{2})_\d+\..*/, #2014-03-22_17-54-59_600.mp4
            /(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})_(?<hour>\d{2})(?<min>\d{2})(?<second>\d{2})\..*/, #20140426_181652.mp4
            /VID_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})_(?<hour>\d{2})(?<min>\d{2})(?<second>\d{2})_\d{3}\..*/, #VID_20130926_102932_272.mp4
        ]

        def get_time_from_name( path )
            name = File.basename( path )
            CreateTimePattern.each do |re|
               md = name.match(re)
               if md
                   return DateTime.new( md[:year].to_i, md[:month].to_i, md[:day].to_i, md[:hour].to_i, md[:min].to_i, md[:second].to_i )
               end
            end
            nil
        end

        def thumbnail?
            file_path.index(".thumbnails") || ( ( File.size( file_path ) < 150 * 1024 ) && ( file_path.index( "thumb" ) || (File.basename(file_path).index(".") == 0 ) || (File.basename(File.dirname(file_path)).index(".") == 0 ) ))
        end

        def detect_create_time
            if !exif.nil?
                [ 'createdate', 'date_time', 'datetimeoriginal', 'modifydate' ].each do |date_fn|
                    if exif[date_fn]   #don't use nil? here, mini_exiftools sometime return nil, sometime return false
                        @create_time = exif[date_fn]
                        @create_time_source = CREATE_TIME_FROM_TAG
                    end
                end
            end

            if @create_time.nil?
                @create_time = get_time_from_name( file_path )
                @create_time_source = CREATE_TIME_FROM_NAME
            end

            if @create_time.nil?
                if mime.type == "video/mpeg"
                    @create_time = @file_mod_time
                    @create_time_source = CREATE_TIME_FROM_MODIFY_TIME
                end
            end
        end

        def image?
            if mime
                mime.image?
            else
                false
            end
        end

        def video?
            if mime
                mime.mediatype == "video"
            else
                false
            end
        end

        def md5sum
            if @md5sum.nil?
                @md5sum = Storage::Md5sum.from_file( file_path )
            end
            @md5sum
        end

        def mime
            if @mime.nil?
                @mime = MimeMagic.by_path( @file_path )
                if @mime.nil?
                    @mime = MimeMagic.by_magic( File.open( @file_path, "rb" ).read( 1024 * 16 ) )
                end
            end
            @mime
        end

        def to_hash
            { :meta_version=>META_VERSION, :file_path=>file_path, :md5sum=>md5sum, :create_time => create_time, :create_time_source=>create_time_source, :file_mod_time => file_mod_time, :mime=>mime, :model=>model, :make=>make, :file_size=>File.size(file_path)  }
        end

        PodFileInfoFields = [ :file_path, :create_time, :md5sum, :create_time_source, :file_mod_time, :mime, :model, :make, :checkin_id, :file_size ]
        PodFileInfo = Struct.new( *PodFileInfoFields ) do
            def image?
                if mime
                    mime.image?
                else
                    false
                end
            end

            def video?
                if mime
                    mime.mediatype == "video"
                else
                    false
                end
            end

            def to_hash
                { :meta_version=>META_VERSION, :file_path=>file_path, :md5sum=>md5sum, :create_time => create_time, :create_time_source=>create_time_source, :file_mod_time => file_mod_time, :mime=>mime, :model=>model, :make=>make, :file_size=>File.size(file_path)  }
            end
        end

        def self.from_hash( hash )
            hash["create_time"] = DateTime.parse( hash["create_time"] )
            hash["file_mod_time"] = Time.parse( hash["file_mod_time"] )
            hash["md5sum"] = Storage::Md5sum.new( hash["md5sum"] )
            hash["mime"] = MimeMagic.new( hash["mime"] )

            PodFileInfo.new( * (PodFileInfoFields.map { |name| hash[name.to_s] }) )
        end

        def write_thumb( file_path )
            if image?
                write_image_thumb( file_path )
            elsif video?
                write_video_thumb( file_path )
            end
        end

        def write_image_thumb( file_path )
            imgs = Magick::Image.read( @file_path )
            #puts "#{@file_path} has #{imgs.length} pictures!"
            width = 640
            height = 480
            if imgs[0].columns > imgs[0].rows then
                height = imgs[0].rows * 640 / imgs[0].columns 
            else
                width = imgs[0].columns * 480 / imgs[0].rows
            end
            #puts "#{width}x#{height}"
            thumb = imgs[0].thumbnail(width, height)
            thumb.write "jpeg:"+file_path
            thumb.destroy!
            imgs[0].destroy!
        end

        def get_av_length(file_path)
            avprobe_output = `avprobe #{file_path} 2>&1`
            match = /Duration: (\d\d):(\d\d):(\d\d).\d\d,/.match(avprobe_output)
            if match.nil?
                0
            else
                match[1].to_i * 3600 + match[2].to_i * 60 + match[3].to_i
            end
        end

        def write_video_thumb( file_path )
            if get_av_length( file_path ) > 20
                offset = 10
            else
                offset = 1
            end
            cmd =  "avconv -itsoffset -#{offset} -i \"#{@file_path}\" -y -an -vsync 1 -vframes 1 -vcodec mjpeg -s 640x480 -f mjpeg #{file_path}"
            if !system(cmd)
                puts "Generate video thumb of [#{@file_path}] error. cmd is [#{cmd}]"
                raise "write video thumb error!"
            end
        end
    end
end
