require 'fileutils'
require 'sequel'
require 'ruiheng/conf'
require 'ruiheng/sync/db'
require 'storage/file_id'
require 'set'

require 'logger'
require 'byebug'

#@TODO need to seprate debug and test mode

module Db
    class Db
        attr_reader :db, :media, :checkin, :day_count, :meta, :tag, :sync, :album, :backup_plan, :backup


        @@db_seq = 1

        def initialize(path, need_migrate)
            if need_migrate
                Sequel.extension :migration
            end

            @db = Sequel.connect( path )


            if need_migrate
                Sequel::Migrator.run(@db, File.dirname(__FILE__)+"/../db/migrations")
            end

            @mod = Object.module_eval( "module ::Db::Db::SubDb%d; self; end" % @@db_seq )
            #TODO multiple thread app may have error.
            @@db_seq += 1
            @mod.const_set( "DB", @db )
            init_model


            if need_migrate
                #Make sure version 0 is a blank database, and next_seq will return from 1
                meta.create( :id=>1, :seq=>1 )
            end
        end

        def time_summary
            self.day_count.group(:year).select_append{ sum(count).as(total) }.all.each do |yrec|
                yield :year, "%d年 (%d)" % [ yrec[:year], yrec[:total] ] ,{ :year=>yrec[:year] }
                self.day_count.where(:year=>yrec[:year]).group(:year, :month).select_append{ sum(count).as(total) }.all.each do |mrec|
                    yield :month, "%d月 (%d)" % [ mrec[:month], mrec[:total] ], { :year=>mrec[:year], :month=>mrec[:month] }
                    self.day_count.where(:year=>mrec[:year], :month=>mrec[:month]).group(:year, :month, :day).select_append{ sum(count).as(total) }.all.each do |rec|
                        yield :day, "%d日 (%d)" % [ rec[:day], rec[:total] ] ,{ :year=>rec[:year], :month=>rec[:month], :day=>rec[:day] }
                    end
                end
            end
        end

        def enable_log
            @db.loggers << Logger.new($stdout)
        end

        def disable_log
            @db.loggers = []
        end

        def seq
            @meta[1].seq
        end

        def inc_seq
            rec = @meta[1]
            rec.seq += 1
            rec.save
            rec.seq
        end

        def camlize(tag)
            tag.to_s.split('_').map{ |item| item.capitalize }.join
        end

        def define_model(model_tag, &proc)
            class_name = camlize(model_tag).chop
            cls = @mod.module_eval( "class %s < Sequel::Model(DB[:%s]); self; end" % [ class_name, model_tag.to_s ] )
            cls.const_set(:SysDb, self )
            cls.class_eval do
                def self.sysdb
                    self.const_get(:SysDb) 
                end
            end
            cls.class_exec( nil, &proc )
            cls
        end

        def init_model
            define_model(:checkins) do
                include Ruiheng::Sync::Model

                unrestrict_primary_key
                def before_save
                    self[:modify_time] = DateTime.now
                    if self[:version].nil?
                        self[:version] = self.class.sysdb.seq
                    end
                end
            end


            define_model(:tags) do
                include Ruiheng::Sync::Model

                unrestrict_primary_key
                many_to_many :medias
                def before_save
                    self[:modify_time] = DateTime.now
                    if self[:version].nil?
                        self[:version] = self.class.sysdb.seq
                    end
                end
            end

            define_model(:albums) do
                include Ruiheng::Sync::Model

                unrestrict_primary_key
                many_to_many :medias
                def before_save
                    self[:modify_time] = DateTime.now
                    if self[:version].nil?
                        self[:version] = self.class.sysdb.seq
                    end
                end
            end

            define_model(:metas) do
                unrestrict_primary_key
            end

            define_model(:syncs) do
                unrestrict_primary_key
                def before_save
                    self[:id] = Storage::Md5sum.from_string( "%s:%d:%s:%d" % [ self[:left_uuid], self[:left_version], self[:right_uuid], self[:right_version] ] )
                end

                def self.ids
                    Set.new self.select_map( :id )
                end

                def self.sync(sync_set)
                    local_ids = self.ids
                    remote_ids = sync_set.ids
                    patch_for_local = remote_ids - local_ids
                    patch_for_remote = local_ids - remote_ids
                    patch_for_local.each do |rec_id|
                        self.create( sync_set[rec_id].values )
                    end
                    patch_for_remote.each do |rec_id|
                        sync_set.create( self[rec_id].values )
                    end
                end

                def self.get_version_info( uuid, remote_uuid )
                    uuid = uuid.to_s
                    remote_uuid = remote_uuid.to_s

                    #Find common base version
                    version_info = self.where( :left_uuid=>uuid, :right_uuid=>remote_uuid ).order( Sequel.desc(:left_version), Sequel.desc(:right_version) ).first
                    if version_info.nil?
                        version_info = { :left_uuid=>uuid, :right_uuid=>remote_uuid, :left_version=>0, :right_version=>0 }
                    end
                    right_first_version_info = self.where( :left_uuid=>remote_uuid, :right_uuid=>uuid ).order( Sequel.desc(:right_version), Sequel.desc(:left_version) ).first

                    if right_first_version_info and ( right_first_version_info[:right_version] > version_info[:left_version] )
                        version_info[:left_version] = right_first_version_info[:right_version]
                        version_info[:right_version] = right_first_version_info[:left_version]
                    end

                    version_info
                end
            end

            define_model(:day_counts) do
                def self.inc_count( values )
                    #puts "inc_count:#{values}"
                   rec = self[ values ] 
                   if rec
                       rec[:count] += 1 
                       rec.save
                   else
                       self.create( values.merge( :count=>1 ) )
                   end
                end

                def self.dec_count( values )
                    puts "dec_count:#{values}"
                   rec = self[ values ]
                   rec[:count] -= 1
                   rec.save
                end
            end

            define_model(:medias) do
                unrestrict_primary_key

                include Ruiheng::Sync::Model

                add_relation_for_sync :album, :tag

                many_to_many :tags, :after_add=>:relation_changed, :after_set=>:relation_changed, :after_remove=>:relation_changed
                many_to_many :albums, :after_add=>:relation_changed, :after_set=>:relation_changed, :after_remove=>:relation_changed

                def relation_changed(relation_obj)
                    self.update( :version=>self.class.sysdb.seq )
                end

                def to_hash_for_day_counts(values = nil)
                    values = self if values.nil?
                    ret = {:year=>values[:year], :month=>values[:month], :day=>values[:day]}
                    ret
                end

                def before_save
                    self[:modify_time] = DateTime.now
                    if self[:create_time]
                        self[:year] = self[:create_time].year
                        self[:month] = self[:create_time].month
                        self[:day] = self[:create_time].day
                    end
                    if self[:version].nil?
                        self[:version] = self.class.sysdb.seq
                    end
                end

                def before_create
                    day_count.inc_count(  to_hash_for_day_counts )
                    @old_values = to_hash_for_day_counts
                end

                def day_count
                    self.class.const_get("DayCount")
                end

                def before_update
                    if @changed_columns.include?(:year) || @changed_columns.include?(:month) || @changed_columns.include?(:day)
                        day_count.dec_count(  to_hash_for_day_counts(self.class[id]) )
                        day_count.inc_count(  to_hash_for_day_counts )
                        @old_values = to_hash_for_day_counts
                    end
                end
            end

            define_model(:backup_plans) do
                unrestrict_primary_key

                one_to_many :backups
            end

            define_model(:backups) do
                unrestrict_primary_key

                many_to_one :backup_plan
            end

            [:media,:checkin, :day_count, :meta, :tag, :album, :sync, :backup_plan, :backup].each do |name|
                instance_variable_set( "@"+name.to_s, @mod.const_get( camlize( name ) ) )
            end

            @media.const_set( "DayCount", @day_count )
            
        end
    end
end


