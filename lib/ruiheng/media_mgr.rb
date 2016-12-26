require 'repo'
require 'sequel'
require 'db'
require 'ruiheng/media_scan'
require 'ruiheng/db_rebuilder'
require 'ruiheng/sync'
require 'ruiheng/sync/media_mgr'
require 'ruiheng/media_mgr/media'
require 'ruiheng/media_mgr/items'
require 'simple_console'

module Ruiheng
    # Manager all the media data and meta info into disk
    #
    # Path layout:
    #     media -- media repo
    #     checkin -- checkin repo
    #     db -- db files
    #     conf -- configure file

    class MediaMgr

        DEFAULT_ALBUM_ID = 1

        attr_reader :db, :uuid, :media, :checkin, :tag, :album, :backup_plan, :console, :root_path

        include Sync::MediaMgr

        def initialize(root_path, media_path=nil)
            @console = SimpleConsole.new
            @root_path = root_path
            if media_path.nil?
                @repo_media = Repo::Media.new( @root_path + "/media" )
            else
                @repo_media = Repo::Media.new( media_path + "/media" )
            end

            @repo_checkin = Repo::Checkin.new( @root_path + "/checkin" )
            if File.exist?( @root_path + "/uuid" )
                @uuid = Storage::Uuid.new( File.read( @root_path + "/uuid" ) )
            else
                @uuid = Storage::Uuid.new
                File.write( @root_path + "/uuid" ,@uuid.to_s )
            end

            FileUtils.mkdir_p @root_path + "/db"
             
            @db = Db::Db.new( "sqlite://" + dbfile_path, !File.exist?(@root_path + "/db/meta.db") )

            FileUtils.mkdir_p @root_path + "/backup"

            if !File.exist? dbfile_backup_path(0)
                backup_db(0)
            end

            @media = Media.new( self, @db.media, @repo_media, @console )
            @media.db.console = @console
            @checkin = MediaMgr::Items.new( @db.checkin, @repo_checkin, @console )
            @tag = MediaMgr::Items.new( @db.tag, nil, @console )
            @album = MediaMgr::Items.new( @db.album, nil, @console )
            @backup_dbs = {}

            if media_path.nil?
                @gabage = @root_path + "/gabage"
            else
                @gabage = media_path + "/gabage"
            end
            if !File.exist? @gabage
                FileUtils.mkdir_p @gabage
            end
        end

        def stat
            {
                :media_count=>db.media.count,
                :album_count=>db.album.count,
                :checkin_count=>db.checkin.count,
            }
        end

        def get_gabage_path
            path = @gabage + "/" + DateTime.now.strftime( "%Y-%m-%d_%H-%M-%S_%3N" )
            FileUtils.mkdir_p path
            path
        end

        def dbfile_path
            @root_path + "/db/meta.db"
        end

        def dbfile_backup_path(version)
            "%s/backup/meta.%s.db" % [ @root_path, version ]
        end

        def set_default_album
            if db.album[DEFAULT_ALBUM_ID].nil?
               db.album.create( :id=>DEFAULT_ALBUM_ID, :name=>"Default", :text=>"Default album to store all new images" ).save; 
            end

            medias_in_album = Set.new db.db["select distinct media_id from albums_medias"].map(:media_id)
            medias = Set.new db.media.map(:id)

            db.db.transaction do
                default_album = db.album[DEFAULT_ALBUM_ID]
                (medias - medias_in_album).each do |id|
                    puts id
                    default_album.add_media( db.media[id] )
                end
            end

            medias_in_other_album = Set.new db.db["select distinct media_id from albums_medias where album_id != '#{DEFAULT_ALBUM_ID}'"].map(:media_id)
            medias_in_default_album = Set.new db.db["select distinct media_id from albums_medias where album_id == '#{DEFAULT_ALBUM_ID}'"].map(:media_id)

            db.db.transaction do
                ( medias_in_other_album & medias_in_default_album ).each do |id|
                    puts "##{id}"
                    default_album.remove_media( db.media[id] )
                end
            end
        end

        def default_album
            db.album[DEFAULT_ALBUM_ID]
        end

        def create_album(name,text)
            db.album.create( :id=>Storage::Uuid.new.to_s, :name=>name, :text=>text )
        end

        def generate_html
            html_path = @root_path + "/www"
            if !File.exist? html_path
                FileUtils.mkdir_p File.dirname(html_path)
                FileUtils.cp_r File.dirname( File.realpath(__FILE__) ) + "/../../res/html/bootstrap", html_path
            end
            Ui::Html::Generator.new( self, html_path ).generate
        end

        def seq
            @db.seq
        end

        def inc_seq
            @db.inc_seq
        end

        def backup_db(version=nil)
            version = seq if version.nil?

            raise "#{dbfile_backup_path(version)} already exist!" if File.exist? dbfile_backup_path(version)
            FileUtils.cp dbfile_path, dbfile_backup_path(version)
            self
        end

        def load_backup_db(version)
            if @backup_dbs[version].nil?
                raise "#{dbfile_backup_path(version)} is not exist!" if !File.exist? dbfile_backup_path(version)
                @backup_dbs[version] = Db::Db.new( "sqlite://" + dbfile_backup_path(version), false )
            end

            @backup_dbs[version]
        end


        def rebuild_db
            DbRebuilder.new( self, @root_path + "/checkin" ).rebuild
        end

        def scan_and_import_media( media_path )
            MediaScan.new( self ).scan( media_path )
        end

        def sync( remote )
            @console.writeln( "Sync start ..." )
            #Sync syncs table
            @console.writeln( "Sync sync table ..." )
            db.sync.sync( remote.db.sync )

            #Find common base version
            version_info = db.sync.get_version_info( uuid, remote.uuid )

            #Apply diffs to local and remote
            self.inc_seq
            remote.inc_seq

            @console.writeln( "Sync local version from %d..%d to remote %d..%d" % [ version_info[:left_version], self.seq, version_info[:right_version], remote.seq ] ) 

            do_sync( version_info[:left_version], remote, version_info[:right_version] )

            @console.writeln ("Update sync table" )
            #Record sync infos
            new_version_info = { :left_uuid=>uuid, :left_version=>self.seq, :right_uuid=>remote.uuid, :right_version=>remote.seq }

            db.sync.create( new_version_info )
            remote.db.sync.create( new_version_info )

            @console.writeln ("Backup meta.db" )
            self.backup_db
            remote.backup_db

            #Make sure sync result occupy one version.
            self.inc_seq
            remote.inc_seq
        end

        def create_backup_plan(name)
            db.backup_plan.create(:id=>Storage::Uuid.new.to_s, :name=>name, :top_version=>0)
        end

        def backup_for_plan(plan_id, sizes)
            backup_plan = db.backup_plan[plan_id]
            raise "backup_plan with #{id} is not exist!" if backup_plan.nil?
            backup = backup_plan.add_backup( :base_version=>backup_plan.top_version + 1, :top_version=>seq )
            path = @root_path + "/media_backups/" + backup.id.to_s
            FileUtils.mkdir_p path
            num = backup_to_path( path, backup_plan.top_version + 1, sizes, { :backup_plan_uuid=>backup_plan.id, :backup_id=>backup.id } )
            backup_plan.update( :top_version=>seq )
            backup.update( :part_number=> num )
            inc_seq
            backup
        end

        def write_backup_part_to_path( backup, part_number, dest_path )
            FileUtils.mkdir_p dest_path
            src_path = @root_path + "/media_backups/" + backup.id.to_s + "/" + part_number.to_s
            raise "Invalid argument" if !File.directory? src_path
            Dir[src_path+"/*"].each do |file|
                FileUtils.cp_r( file, dest_path )
            end

            remote = MediaMgr.new( dest_path )
            remote.media.copy_or_update_records_repo( remote.media.db.all, self.media )
        end

        #Backup function define: tags, albums, syncs, backups, backup_plans, checkins all duplicated. medias updated seperately.
        def backup_to_path( dest_path, base_version, sizes, backup_meta={})
            top_version = self.seq
            media_list = media.db.diff_with_time( base_version )
            
            disk_list =MediaMgr.split_media_list_by_maxsize( media_list, sizes )
            meta = { :type=>1, :source_uuid=>uuid, :source_base_version=>base_version, :source_top_version=>self.seq, :backup_part_number=>disk_list.length  }.merge( backup_meta )
            disk_list.each_with_index do |medias, i|
                remote_path = "%s/%d" % [ dest_path, i ]
                puts "Backup from %s to %s into %d" % [ medias.first.create_time.strftime( "%Y/%m/%d" ), medias.last.create_time.strftime( "%Y/%m/%d" ), i ]
                FileUtils.mkdir_p remote_path
                FileUtils.touch "%s/%s_to_%s_%d" % [ remote_path, medias.first.create_time.strftime( "%Y-%m-%d" ), medias.last.create_time.strftime( "%Y-%m-%d" ), i ]
                meta[:backup_seq] = i
                backup_to_repo( medias, remote_path, meta )
            end

            disk_list.length
        end

        def backup_to_repo( medias, remote_path, meta )
            remote = MediaMgr.new( remote_path )

            remote.db.db.transaction do 
                [:tag, :album, :checkin].each do |name|
                    remote.send(name).copy_or_update_records( self.send(name).db.all, self.send(name), remote.seq )
                end
                remote.media.copy_or_update_records_db( medias, self.media, remote.seq )
                #remote.db.meta[1].update( :type=>1, :source_uuid=>uuid, :source_base_version=>base_version, :source_top_version=>self.seq ).save
                remote.db.meta[1].update( meta )
            end
            
        end

        def self.split_media_list_by_maxsize( media_list, sizes )
            result = []
            accumated_size = 0
            current_list = []
            maxsize = sizes.shift
            media_list.each do |media|
                accumated_size += media.file_size + 100 * 1024
                if ( accumated_size > maxsize ) && (!current_list.empty?)
                    accumated_size = media.file_size + 100 * 1024
                    result << current_list
                    current_list = []
                    maxsize = sizes.shift if !sizes.empty?
                end
                current_list << media
            end

            if !current_list.empty?
                result << current_list
            end

            result
        end

        def old_backup_to_path( dest_path, base_version, top_version=nil )
            top_version = self.seq if top_version.nil?

            backup_seq = 0

            remote = MediaMgr.new( dest_path )

            remote.inc_seq

            remote.db.db.transaction do 
                backup_to( base_version, top_version, remote )
                remote.db.meta[1].update( :type=>1, :source_uuid=>uuid, :source_base_version=>base_version, :source_top_version=>self.seq ).save
            end

            #Make sure backup to a fix status of version 
            self.inc_seq
        end

        def add_tag(media_list, tag_string)
            add_mark(media_list, tag_string, self.tag.db, :text )
        end

        def add_album(media_list, album_string)
            add_mark(media_list, album_string, self.album.db, :name )
        end

        def add_album_by_id( media_list, album_id )
            db.db.transaction do
                album = self.album.db[:id=>album_id]
                media_id_in_album = Set.new album.medias.map{ |i| i.id}
                default_album_id = default_album.id
                media_id_in_default_album =  Set.new default_album.medias.map{ |i| i.id }
                raise "Invalid album id #{album_id}" if album.nil?
                p media_list
                media_list.each do |img|
                    if !media_id_in_album.include? img.id
                        puts "add image #{img.id} to album #{album.name}"
                        album.add_media(img)
                        if ( album.id != default_album_id ) && ( media_id_in_default_album.include?(img.id) )
                            default_album.remove_media(img)
                        end
                    end
                end
            end
        end

        def add_mark(media_list, mark_string, db, string_field_name)
            mark = db[string_field_name=>mark_string]
            if mark.nil?
                mark = db.create( :id=>Storage::Uuid.new.to_s, string_field_name=>mark_string )
            end
            media_list.each do |img|
                if !mark.medias.map{ |i| i.id}.include? img.id
                    mark.add_media(img)
                end
            end
        end

        def calculate_backup_size( base_version, top_version=nil )
            top_version = self.seq if top_version.nil?
            db.media.where( :version=>base_version..top_version ).sum( :file_size )
        end

        def calculate_version_sizes( base_version, top_version=nil )
            top_version = self.seq if top_version.nil?
            db.media.where( :version=>base_version..top_version ).select_group(:version).select_append{sum( :file_size ).as( :file_size )}.all.inject({}) { |h,rec| h[rec[:version]] = rec[:file_size]; h }
        end
    end
end
