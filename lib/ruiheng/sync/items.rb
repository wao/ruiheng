module Ruiheng
    module Sync
        module Items
            def apply_patch( patch, remote, seq )
                patch.each_with_index do |rec_id,i|
                    @console.write  13.chr + (  "Apply patch to %d of %d"  % [ i+1, patch.length ] ) 
                    #Update media db
                    value = remote.db[rec_id].values
                    copy_or_update_record( rec_id, value, remote, seq )
                end
                puts
            end

            def copy_or_update_record_db( rec_id, value, remote, seq )
                rec = self.db[rec_id]
                value[:version]=seq
                #TODO maybe need to compare first
                if rec
                    rec.update( value ).save 
                else
                    value[:id] = rec_id
                    rec = self.db.create( value )
                end

                rec.apply_relation_patch( remote.db[rec_id] )
            end

            def copy_or_update_record_repo( rec_id, remote )
                if self.repo
                    storage_id = Storage::Md5sum.new(rec_id)
                    if ! self.repo.exist? storage_id
                        remote.repo.copy_to_repo( storage_id, self.repo )
                    else
                        puts "#{rec_id} already exist!"
                    end
                end
            end

            def copy_or_update_record( rec_id, value, remote, seq )
                copy_or_update_record_db( rec_id, value, remote, seq )
                copy_or_update_record_repo( rec_id, remote )
            end

            def copy_or_update_records(recs, remote, seq)
                recs.each do |rec|
                    copy_or_update_record( rec.id, rec.values, remote, seq )
                end
            end

            def copy_or_update_records_db(recs, remote, seq)
                recs.each do |rec|
                    copy_or_update_record_db( rec.id, rec.values, remote, seq )
                end
            end

            def copy_or_update_records_repo(recs, remote)
                recs.each do |rec|
                    copy_or_update_record_repo( rec.id, remote )
                end
            end

            def sync( local_clean_diff, remote_clean_diff, conflicts, local_base_db, local_seq, remote, remote_base_db, remote_seq )
                self.apply_patch( remote_clean_diff, remote, local_seq )
                remote.apply_patch( local_clean_diff, self, remote_seq )
                self.db.resolve_conflicts( conflicts, local_base_db, local_seq, remote.db, remote_base_db, remote_seq )
            end


            def diff(base_version, top_version=nil)
                top_version = self.db.seq if top_version.nil?
                db.diff( base_version, top_version )
            end
        end
    end
end
