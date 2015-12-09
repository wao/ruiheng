module Ruiheng
    module Sync
        module Model
            def self.included(mod)
                mod.extend( self::ClassMethods )
            end

            Diff = Struct.new( :value, :relation ) do
                def merge(values)
                    Diff.new( self.value.merge( values.value ), self.relation.merge( values.relation ) )
                end

                def empty?
                    value.empty? && relation.empty?
                end
            end

            RelationDiff = Struct.new( :added, :removed, :current ) do
                def merge(values)
                    #added_and_removed = self.added & values.removed
                    #removed_and_added = self.removed & values.added

                    #TODO need to consider following sceneor: same tag text but different id ( rename ),   same tag text add in one place and removed in another places
                    RelationDiff.new( nil, nil, self.current - values.removed + values.added )
                end

                def to_ids
                    current.to_a
                end

                def empty?
                    added.empty? && removed.empty?
                end
            end

            class RelationDiffs 
                attr_reader :diffs

                def initialize(diffs)
                    @diffs = diffs || {}
                end

                def [](key)
                    @diffs[key]
                end

                def []=(key,value)
                    @diffs[key]=value
                end

                def merge(values)
                    result = {}
                    @diffs.each_pair do |key, value|
                        result[key] = value.merge( values[key] )
                    end
                    RelationDiffs.new(result)
                end

                def empty?
                    @diffs.values.inject( true ) { |r, v| r && v.empty? }
                end
            end

            def diff( base_rec )
                result = Diff.new(diff_value(base_rec),diff_relation(base_rec) )
                my_assert !result.empty?
                result
            end

            def diff_value( base_rec )
                result = self.values.reject do |field_name, field_value|
                    field_value == base_rec[field_name]
                end

                my_assert result.has_key? :version
                result.delete :version

                result.delete :modify_time

                result
            end

            def diff_relation( base_rec )
                result = {}
                self.class.relations.each do |relation|
                    self_ids = Set.new relation.get( self )
                    base_ids = Set.new relation.get( base_rec )
                    result[relation.relation_name] = RelationDiff.new( self_ids - base_ids, base_ids - self_ids, self_ids )
                end
                RelationDiffs.new(result)
            end

            def apply_relation_patch( values )
                self.class.relations.each do |relation|
                    relation.set( self, relation.get(values) )
                end
            end


            class RelationSyncHelper
                def initialize( relation_name )
                    @relation_name = relation_name.to_s
                    @setter =  ("%ss=" % @relation_name).to_sym 
                    @getter =  ("%ss" % @relation_name).to_sym 
                end

                def relation_name
                    @relation_name.to_sym
                end
                
                def set(obj, ids)
                    obj.send(@setter,ids)
                end

                def get(obj)
                    obj.send(@getter).map{ |o| o.id }
                end
            end


            module ClassMethods

                RelationMethods = <<__END__
                    def %ss=(ids)
                        remove_all_%ss
                        ids.each do |id|
                            add_%s(id)
                        end
                    end
__END__

                def add_relation_for_sync( *names )
                    @relations ||= []
                    names.each do |name|
                        class_eval ( RelationMethods % Array.new(3,name.to_s) )
                        @relations  << RelationSyncHelper.new( name )
                    end
                end

                def relations
                    @relations ||= []
                end

                def console
                    @console ||= NullLogger.new
                end

                def console=(value)
                    @console = value
                end

                def resolve_conflicts( conflicts, local_base_table, local_seq, remote_table, remote_base_table, remote_seq )
                    conflicts.each_with_index do |rec_id, i|
                        console.writeln( "Resolve conflict %d of %d" % [ i, conflicts.length ] )
                        local_rec = self[rec_id]
                        local_rec_base = local_base_table[rec_id]
                        local_diff = local_rec.diff( local_rec_base )

                        remote_rec = remote_table[rec_id]
                        remote_rec_base = remote_base_table[rec_id]
                        remote_diff = remote_rec.diff( remote_rec_base )

                        #Remove conflicts by timestamp
                        final_diff = if local_rec.modify_time < remote_rec.modify_time
                                         local_diff.merge( remote_diff )
                                     else
                                         remote_diff.merge( local_diff )
                                     end

                        relations.each do |relation|
                            relation.set( local_rec, final_diff.relation[relation.relation_name].to_ids )
                            relation.set( remote_rec, final_diff.relation[relation.relation_name].to_ids )
                        end

                        final_diff.value[:version] = local_seq
                        local_rec.update(final_diff.value)

                        final_diff.value[:version] = remote_seq
                        remote_rec.update(final_diff.value)
                    end
                end


                def diff(base_version, top_version=nil)
                    top_version = self.sysdb.seq if top_version.nil?
                    base_version += 1
                    Set.new( self.filter( :version=>base_version..top_version ).select_map(:id) )
                end

                def diff_with_time(base_version, top_version=nil)
                    top_version = self.sysdb.seq if top_version.nil?
                    base_version += 1
                    self.filter( :version=>base_version..top_version ).order(:create_time).all
                end
            end
        end
    end
end
