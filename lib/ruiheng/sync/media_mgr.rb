module Ruiheng
    module Sync
        module MediaMgr
            def backup_to( self_base_version, top_version, remote )
                remote_seq = remote.seq


                [ :tag, :album, :media,:checkin ].each do |component|
                    #Caculate diffs
                    local_diff = self.send(component).db.diff( self_base_version, top_version )

                    remote.send(component).apply_patch( local_diff, self.send(component), remote_seq )
                end
            end

            def do_sync(local_base_version, remote, remote_base_version)
                local_seq = self.seq
                remote_seq = remote.seq

                #Tag must be first, since media will use it.
                [ :tag, :album, :media, :checkin ].each do |component|
                    #Caculate diffs
                    local_diff = self.send(component).db.diff( local_base_version, local_seq - 1 )
                    remote_diff = remote.send(component).db.diff( remote_base_version, remote_seq - 1 )

                    #Caculate conflicts
                    conflicts = local_diff & remote_diff
                    local_clean_diff = local_diff - conflicts
                    remote_clean_diff = remote_diff - conflicts

                    @console.writeln( "Sync %s: local patch %d, remote patch %d, conflicts %d" % [ component.to_s, local_clean_diff.length, remote_clean_diff.length, conflicts.length ] )

                    self.send(component).sync( local_clean_diff, remote_clean_diff, conflicts, self.load_backup_db(local_base_version).send(component), local_seq, remote.send(component), remote.load_backup_db(remote_base_version).send(component), remote_seq )

                end
            end
        end
    end
end
