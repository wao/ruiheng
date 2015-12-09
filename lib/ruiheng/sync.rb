module Kernel
    def my_assert(value, msg = nil)
        raise  "Assert failed!" if !value
    end
end

module Ruiheng
    module Sync
        def self.sync(local, local_base_version, remote, remote_base_version)
            local_seq = local.seq
            remote_seq = remote.seq

            #Tag must be first, since media will use it.
            [ :tag, :album, :media, :checkin ].each do |component|
                #Caculate diffs
                local_diff = local.send(component).db.diff( local_base_version, local_seq - 1 )
                remote_diff = remote.send(component).db.diff( remote_base_version, remote_seq - 1 )

                #Caculate conflicts
                conflicts = local_diff & remote_diff
                local_clean_diff = local_diff - conflicts
                remote_clean_diff = remote_diff - conflicts

                local.send(component).sync( local_clean_diff, remote_clean_diff, conflicts, local.load_backup_db(local_base_version).send(component), local_seq, remote.send(component), remote.load_backup_db(remote_base_version).send(component), remote_seq )

            end
        end
    end
end
