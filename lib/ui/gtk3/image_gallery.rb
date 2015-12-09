require 'gtk3'

require 'ui/gtk3/image'

module Ui
    module Gtk3
        class ImageGallery < Gtk::Box
            type_register

            signal_new( "selected",
                       GLib::Signal::RUN_FIRST,
                       nil,
                       nil,
                       Integer,
                       Integer
                      )

            attr_reader :global

            def initialize( global, col, row, checkable = false )
                super( :orientation=>Gtk::Orientation::VERTICAL )
                @global = global
                @checks = []
                @col = col
                @row = row
                @page_ind = 0
                @img_infos = []

                @grid_pics = Gtk::Table.new col-1, row-1, true
                pack_start @grid_pics, :expand=>true, :fill=>true

                @lbl_navigator = Gtk::Label.new
                @lbl_navigator.wrap = true
                pack_start @lbl_navigator, :expand=>false, :fill=>true


                init_pics_table( @grid_pics, checkable )
                @lbl_navigator.signal_connect "activate-link" do |w, url, user_data|
                    puts "url:#{url}"
                    case url
                    when 'next'
                        @page_ind += 1
                    when 'prev'
                        @page_ind -= 1
                    else
                        @page_ind = url.to_i
                    end

                    @lbl_navigator.markup = get_navitator_text 
                    refresh
                end

                @keep_xy_ratio = false
            end

            def keep_xy_ratio=(value)
                @keep_xy_ratio = value
                refresh
            end

            def sync_checks_status
                0.upto(@checks.length - 1 ) do |i|
                    pos =  @page_ind * @col * @row + i 
                    if pos < @img_infos.length
                        @checks[i].set_active( global.selection.include?(@img_infos[ pos ].id ) )
                    else
                        @checks[i].set_active( false )
                    end
                end
            end

            def refresh
                sync_checks_status
                queue_draw
            end

            def hide_checks
                @checks.each{ |check| check.hide }
            end

            def show_checks
                sync_checks_status
                @checks.each{ |check| check.show }
            end

            def page_count
                ( @img_infos.length + (@col*@row-1) ) / (@col * @row)
            end

            def img_infos= (images)
                @img_infos = images if images
                @page_ind = 0
                @lbl_navigator.markup = get_navitator_text 
            end

            def update_image_infos
                @lbl_navigator.markup = get_navitator_text 
                refresh 
            end

            def signal_do_selected(pos,value)
            end

            def get_pixbuf(pos)
                if pos < @img_infos.length
                    #puts Global.inst.media_mgr.media.repo.thumb_path( Storage::Md5sum.new(@img_infos[pos].id ) )
                    Gdk::Pixbuf.new( :file =>  global.media_mgr.media.repo.thumb_path( Storage::Md5sum.new(@img_infos[pos].id ) ) ) 
                else 
                    nil
                end
            end

            def get_tooltip(pos)
                if pos < @img_infos.length
                    info = @img_infos[pos]
                    [info.create_time.to_s, info.id.to_s, info.file_path.to_s].join("\n")
                else
                    ""
                end
            end

            def gen_link_text(i)
                if i == @page_ind
                    color = 'red'
                else
                    color = 'blue'
                end

                '<span color="%s"><a href="%d">%d</a></span>' % [ color, i, i ]
            end


            TEXT_PREV = '<a href="prev">&lt;</a>'
            TEXT_NEXT = '<a href="next">&gt;</a>'

            def prev_text
                if @page_ind != 0
                    TEXT_PREV
                else
                    "&lt;"
                end
            end

            def next_text
                if @page_ind < page_count - 1
                    TEXT_NEXT
                else
                    "&gt;"
                end
            end

            def get_navitator_text
                '<span font_size="x-large" weight="heavy">' + (0...page_count).map{ |i| gen_link_text(i) }.push(prev_text, next_text).join( " " ) + '</span>'
            end

            def init_pics_table( grid, checkable )
                0.upto(@row-1).each do |y|
                    0.upto(@col-1).each do |x|
                        img = Gtk::DrawingArea.new
                        img.set_size_request 80, 60 
                        pos = x + y * @col
                        img.signal_connect( "draw" ) do |w,cr|
                            if @page_ind * @col * @row + pos < @img_infos.length
                                Image.draw_image( cr, get_pixbuf(@page_ind * @col * @row + pos), w.allocation.width, w.allocation.height, @img_infos[@page_ind * @col * @row + pos].rotate, @keep_xy_ratio )
                            end
                            cr.save do
                                if  false and (@page_ind * @col * @row + pos < @img_infos.length)
                                    text = get_text( @page_ind * @col * @row + pos )
                                    cr.select_font_face( "Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
                                    cr.set_font_size( 15 )
                                    cr.move_to( 0, cr.text_extents(text).height + 5 )
                                    cr.set_source_rgba( 1, 1, 1 )
                                    cr.show_text( text )
                                    #cr.fill
                                end
                            end
                            true
                        end

                        btn = Gtk::Button.new
                        btn.has_tooltip = true
                        btn.signal_connect( 'query-tooltip' ) do |w,x,y,keyboard_mode,tooltip,userdata|
                            tooltip.text = get_tooltip( @page_ind * @col * @row + pos )
                            true
                        end
                        #box = Gtk::VBox.new false
                        #btn.add box
                        #box.pack_start img, true, true 
                        #lbl = Gtk::Label.new
                        #box.pack_end lbl, false, true
                        overlay = Gtk::Overlay.new
                        #overlay.halign = overlay.valign = Gtk::Widget::Align::START
                        overlay.add img
                        btn.add overlay

                        if checkable
                            check = Gtk::CheckButton.new
                            overlay.add_overlay check
                            @checks << check
                            check.get_property("active")
                            check.signal_connect "toggled" do |w|
                                i = @page_ind * @col * @row + pos
                                if i < @img_infos.length
                                    if w.active?
                                        global.selection.add @img_infos[ i ].id
                                    else
                                        global.selection.delete @img_infos[ i ].id
                                    end
                                    self.signal_emit( "selected", @page_ind * @col * @row + pos, w.active? ? 1 : 0 )
                                end
                            end
                        end

                        btn.signal_connect( "clicked" ) do |w,d|
                            img = @img_infos[@page_ind * @col * @row + pos]
                            case img.mime.split('/')[0]
                            when 'image'
                                ViewWindow.new( global, @img_infos, @page_ind * @col * @row + pos ).show
                            when 'video'
                                system( "vlc #{global.media_mgr.media.repo.media_path( Storage::Md5sum.new(img.id) )}" )
                            end
                        end
                        #btn.set_image(img)
                        #img.add_event( Gdk::Event::Mask::BUTTON_PRESS_MASK | Gdk::Event::Mask::BUTTON_RELEASE_MASK )
                        grid.attach btn, x, x+1, y, y+1, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::SHRINK | Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::SHRINK | Gtk::AttachOptions::FILL
                    end
                end
            end
        end
    end
end
