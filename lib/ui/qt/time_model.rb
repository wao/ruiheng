require 'db'

class TimeModel < Qt::AbstractItemModel
    class Item
        attr_reader :sb_level, :i_count, :a_param, :item_parent

        def initialize( model, item_parent, sb_level, a_param, i_count )
            @model = model
            @item_parent = item_parent
            @sb_level = sb_level
            @a_param = a_param
            @i_count = i_count
            @a_children = nil
        end

        def index_parent
            case @sb_level
            when :root
                nil 
            when :year
                nil 
            else
                @item_parent
            end
        end

        def a_children
            load_children if @a_children.nil?
            @a_children
        end

        def row_count
            a_children.length
        end

        def columnCount
            1
        end

        def data
            case @sb_level
            when :root
                Qt::Variant.new
            else
                Qt::Variant.new( "%d(%d)" % [ @a_param[@a_param.length-1], @i_count ] )
            end
        end

        def flags
            case @sb_level
            when :root
                Qt::ItemIsEnabled
            else
                Qt::ItemIsEnabled | Qt::ItemIsSelectable
            end
        end

        def load_children
            #puts "load children: " + @sb_level.to_s
            case @sb_level
            when :root
                @a_children = @model.db.day_count.group(:year).select_append{ sum(count).as(total) }.all.map do |rec|
                    Item.new( @model, self, :year, [ rec.year ], rec[:total] )
                end

            when :year
                @a_children = @model.db.day_count.where(:year=>a_param[0]).group(:year, :month).select_append{ sum(count).as(total) }.all.map do |rec|
                    Item.new( @model, self, :month, [ rec.year, rec.month ], rec[:total] )
                end
            when :month
                @a_children = @model.db.day_count.where(:year=>a_param[0], :month=>a_param[1]).group(:year, :month, :day).select_append{ sum(count).as(total) }.all.map do |rec|
                    puts "%d/%d/%d : %d" % [ rec.year, rec.month, rec.day, rec[:total] ]
                    Item.new( @model, self, :day, [ rec.year, rec.month, rec.day ], rec[:total] )
                end
            when :day
                @a_children = []
            end
        end

        def index(row, column)
            if row >= a_children.length
                nil
            else
                return @a_children[row]
            end
        end
    end

    attr_reader :db

    def initialize(db)
        @db = db

        super(nil)

        @item_root = Item.new( self, nil, :root, [], 0 )
    end

    def index2item(index)
        if !index.valid?
            return @item_root
        else
            #puts "********* %d:%d:%s" %[ index.row, index.column, index.internalPointer.class.to_s ]
            index.internalPointer
        end
    end

    def columnCount(parent)
        1
    end

    def data(index, role)
        if role != Qt::DisplayRole
            Qt::Variant.new
        else
            #puts "data: %d:%d :%s : %s" % [ index.row, index.column, index.internalPointer.to_s, if index.internalPointer.nil? then; "nil"; else index.internalPointer.sb_level.to_s end ]
            index2item(index).data
        end
    end

    def flags(index)
        index2item( index ).flags
    end

    def headerData(section, orientation, role)
        #if orientation == Qt::Horizontal && role == Qt::DisplayRole
        #return Qt::Variant.new(@rootItem.data(section))
        #    return Qt::Variant.new(@rootItem.data(section))
        #end

        return Qt::Variant.new('head')
    end

    def item2index(row, column, item)
        if item.nil?
            Qt::ModelIndex.new
        else
            createIndex(row, column, item)
        end
    end

    def index(row, column, parent)
        #puts "index %d:%d:%s:%s" % [ row, column, parent.internalPointer.to_s, if parent.internalPointer.nil? then; "nil"; else parent.internalPointer.sb_level.to_s end ]
        item2index(row, column, index2item(parent).index(row, column))
    end

    def parent(index)
        item2index(0, 0, index2item(index).index_parent)
    end

    def rowCount(parent)
        index2item(parent).row_count
    end
end
