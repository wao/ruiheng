Sequel.migration do
    up do
        create_table(:metas) do
            primary_key :id
            Integer :seq
            Integer :schema_version, :default=>1
            Integer :type, :null=>false, :default=>0   #0: normal repo, 1: readonly backup
            String :source_uuid   #repo uuid of source if repo is readonly backup
            String :backup_plan_uuid
            Integer :backup_id
            String :source_base_version 
            String :source_top_version 
            Integer :backup_seq
            Integer :backup_part_number
        end

        create_table(:syncs) do
            String :id, :null=>false, :primary_key=>true  #id should be md5sum of left_uuid:left_version:right_uuid:right_version
            String :left_uuid, :null=>false
            Integer :left_version, :null=>false
            String :right_uuid, :null=>false
            Integer :right_version, :null=>false
        end

        create_table(:backup_plans) do
            String :id, :null=>false, :primary_key=>true 
            String :name
            Integer :top_version
            Integer :status, :default=>0
        end

        create_table(:backups) do
            primary_key :id
            String :backup_plan_id
            Integer :base_version
            Integer :top_version
            Integer :part_number
            Integer :status, :default=>0
        end

        create_table(:medias) do
            String :id, :null=>false, :primary_key=>true
            String :file_path
            String :checkin_id
            String :mime
            Integer :year, :null=>false
            Integer :month, :null=>false
            Integer :day, :null=>false
            DateTime :create_time, :index=>true, :null=>false
            Integer :create_time_source #1->photo tag, 2->from filename, 3->last modify time, 4->from user
            DateTime :file_mod_time
            String :model
            String :make
            Integer :file_size
            Integer :version  #change medias, and add/remove tag will reflect to version hange.
            Integer :rotate, :default=>0
            DateTime :modify_time
            Integer :status, :default=>0
        end

        create_table(:tags) do
            String :id, :null=>false, :primary_key=>true
            String :text, :null=>false, :unique=>true, :index=>true
            Integer :version
            DateTime :modify_time
            Integer :status, :default=>0
        end

        create_table(:albums) do
            String :id, :null=>false, :primary_key=>true
            String :name, :null=>false, :unique=>true, :index=>true
            String :text
            Integer :version
            DateTime :modify_time
            Integer :status, :default=>0
        end

        create_table(:medias_tags) do
            primary_key :id
            String :media_id
            String :tag_id
            index [:media_id,:tag_id], :unique=>true
        end

        create_table(:albums_medias) do
            primary_key :id
            String :media_id
            String :album_id
            index [:media_id,:album_id], :unique=>true
        end

        create_table(:checkins) do
            String :id, :null=>false, :primary_key=>true
            DateTime :time, :index=>true
            String :src_path
            Integer :total_count
            Integer :not_media_count
            Integer :already_in_repo_count
            Integer :added_count
            Integer :error_count
            Integer :thumbnail_count
            Integer :version
            DateTime :modify_time
            Integer :status, :default=>0
        end

        create_table(:day_counts) do
            primary_key :id
            Integer :status, :default=>0
            Integer :year, :null=>false
            Integer :month, :null=>false
            Integer :day, :null=>false
            Integer :count, :null=>false
        end

        
    end

    down do
        drop_table(:medias)
        drop_table(:checkins)
        drop_table(:day_counts)
    end
end
