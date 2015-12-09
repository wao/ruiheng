#!/usr/bin/env ruby

$: << File.dirname(__FILE__) + "/../lib"

require 'Qt'
require 'ui/flow_widget'
require 'ui/flowlayout'
require 'ui/main_window'
require 'ruiheng'
require 'storage/file_id'
require 'ui/time_model'
require 'ui/image_view'



class MainWindow < Qt::MainWindow
    slots 'onTreeDblClicked(const QModelIndex&)',"sizeChanged()","linkActivated(const QString&)", "onImageClick(int)", "onBtnBackClick(bool)","tvTimeContextMenu(const QPoint&)"

    def initialize(parent,media_mgr)
        super(parent)

        @media_mgr = media_mgr

        @ui = Ui::MainWindow.new
        @ui.setupUi(self)

        #@l_images = Ui::FlowLayout.new
        @l_images = Qt::GridLayout.new
        #@l_images = Qt::VBoxLayout.new
        @ui.w_images.layout = @l_images

        @images = []

        connect(@ui.tv_time, SIGNAL("doubleClicked( const QModelIndex&)"), self, SLOT('onTreeDblClicked(const QModelIndex&)') )
        connect(@ui.lbl_navigator, SIGNAL("linkActivated(const QString&)"), self, SLOT("linkActivated(const QString&)"))
        connect(@ui.btn_back, SIGNAL("clicked(bool)"), self, SLOT('onBtnBackClick(bool)') )
        #connect(@ui.w_images, SIGNAL("sizeChanged()"), self, SLOT('sizeChanged()') )
        connect(@ui.tv_time, SIGNAL("customContextMenuRequested(const QPoint&)"), self, SLOT("tvTimeContextMenu(const QPoint&)"))


        load_tree( @ui.tv_time )
        #load_pic( @l_images, @ui.w_images )

        #@ui.w_images.install_event_filter( self )

        @label_images = []
        (0...4).each do |y|
            (0...4).each do |x|
                puts x + y * 4
                w_image = MyImageView.new(@ui.w_images)
                @l_images.addWidget( w_image, y, x )
                w_image.custom_data = x + y * 4
                connect( w_image, SIGNAL("onClick(int)"), self, SLOT("onImageClick(int)") )
                @label_images << w_image
            end
        end

        @ui.tv_time.contextMenuPolicy = Qt::CustomContextMenu

    end

    def tvTimeContextMenu(pos)
        puts "context reqest:"+pos.to_s
        indexs = @ui.tv_time.selectionModel.selectedIndexes
        if indexs.length > 0
            puts indexs[0].internalPointer.param
        end
    end

    def onBtnBackClick(checked)
        @ui.stack_main.setCurrentIndex(0)
    end

    def onImageClick(tag)
        puts "click "+tag.to_s
        @ui.lbl_big_image.pixmap = get_big_image(tag)
        @ui.stack_main.setCurrentIndex(1)
    end

    def sizeChanged()
            #puts "************ resize event"
            #reload_pics
    end

    def linkActivated(link)
        case link
        when 'prev'
            if @i_line_index > 0
                if @i_line_index % 4
                    @i_line_index -= 4
                else
                    @i_line_index -= @i_line_index % 4
                end
            end
        when 'next'
            if @i_line_index < @i_lines - 1
                if @i_line_index % 4
                    @i_line_index += 4
                else
                    @i_line_index += 4 - @i_line_index % 4
                end
            end
        else
            @i_line_index = link.to_i * 4
        end

        update_images
    end

    def load_tree(tv)
        tv.model = TimeModel.new(@media_mgr.db)
    end

    def onTreeDblClicked(index)
        puts "dbl_clicked"
        if index.valid?
            item = index.internalPointer
            if item.sb_level == :day 
                puts "day click"
                load_pic_from_db( *item.param )
                update_images
            end
        end
    end

    def i_images_num
        @images.length
    end

    def load_pic_from_db(year, month, day)
        @images = @media_mgr.db.media.filter( :year=>year, :month=>month, :day=>day ).order(:create_time).all
        puts @images.length
        @i_lines = i_images_num/i_pic_num_per_line
        if i_images_num % i_pic_num_per_line 
            @i_lines += 1
        end
        @i_line_index = 0
    end

    def i_pic_num_per_line
        4
    end

    def get_big_image(index)
        i_current = index + @i_line_index * i_pic_num_per_line
        if i_current < i_images_num
            Qt::Pixmap.fromImage(Qt::Image.new( @media_mgr.repo_media.media_path( Storage::Md5sum.new( @images[i_current].id ) )))
        else 
            Qt::Pixmap.new
        end
    end

    def get_tag(index)
        i_current = index + @i_line_index * i_pic_num_per_line
        if i_current < i_images_num
            @images[i_current][:tags]
        else 
            nil
        end
    end

    def get_image(index)
        i_current = index + @i_line_index * i_pic_num_per_line
        if i_current < i_images_num
            puts i_current
            Qt::Pixmap.fromImage(Qt::Image.new( @media_mgr.repo_media.thumb_path( Storage::Md5sum.new( @images[i_current].id ) )))
        else 
            Qt::Pixmap.new
        end
    end

    def prev_next_text

    end

    def i_page_num
        v = @i_lines / 4
        if @i_lines % 4
            v += 1
        end

        v
    end

    def i_current_page
        @i_line_index / 4
    end

    def gen_link_text(i)
        if i == i_current_page
            color = 'red'
        else
            color = 'blue'
        end

        '<a style="text-decoration:none;color:%s;" href="%d">%d</a>' % [ color, i, i ]
    end

    TEXT_PREV = '<a style="text-decoration:none" href="prev">&lt;</a>'
    TEXT_NEXT = '<a style="text-decoration:none" href="next">&gt;</a>'

    def prev_text
        if i_current_page != 0
            TEXT_PREV
        else
            "&lt;"
        end
    end

    def next_text
        if i_current_page < i_page_num - 1
            TEXT_NEXT
        else
            "&gt;"
        end
    end

    def update_images
        (0...16).each do |i|
            @label_images[i].pixmap = get_image(i)
            @label_images[i].text = get_tag(i)

        end
        @ui.lbl_navigator.text = (0...i_page_num).map{ |i| gen_link_text(i) }.push(prev_text, next_text).join( "&nbsp;" ) 
    end
        
    def load_image(elem,l_layout,w_parent)
            puts elem
            image = Qt::Image.new(elem)

            @label_images[@x*4 + @y].pixmap = Qt::Pixmap.fromImage(image)

            @x += 1
            if @x > 3
                @y += 1
                @x = 0
            end
    end

    def load_pic(l_layout, w_parent)
        num = 0
        Dir['/home/w19816/already-backup/20140706-lx7/101_PANA/*'].each do |elem|
            load_image(elem,l_layout,w_parent)

            num += 1
            if num > 4
                break
            end
        end
    end
end


app = Qt::Application.new ARGV

media_mgr = Ruiheng::MediaMgr.new( ARGV[0] )

w_main = MainWindow.new(nil, media_mgr)

w_main.show

app.exec
