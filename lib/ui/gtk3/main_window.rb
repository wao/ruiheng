require 'ui/gtk3/selection_window'

module Ui
    module Gtk3
        class MainWindow
            attr_reader :global

            def initialize(global)
                @global = global
                @checks = []
                @builder = global.builder
                @wnd_main = @builder.get_object( "wnd_main" )
                #puts @wnd_main.class
                @wnd_main.signal_connect( "destroy" ) { |w| Gtk.main_quit }
                @wnd_main.set_default_size 800,600

                @select_window = SelectionWindow.new(global)

                @builder.get_object( "act_select_mode" ).signal_connect "toggled" do |w|
                    if w.active?
                        @select_window.show
                        show_checks
                    else
                        @select_window.hide
                        hide_checks
                    end
                end

                @img_range_1 = @builder.get_object( "img_range_1" )
                @img_range_2 = @builder.get_object( "img_range_2" )
                @btn_add_range = @builder.get_object( "btn_add_range" )

                @builder.get_object( "act_scale_mode" ).signal_connect "toggled" do |w|
                    @image_gallery.keep_xy_ratio = !w.active?
                end

                @image_gallery = Ui::Gtk3::ImageGallery.new( global, 4, 4, true )
                @builder.get_object( "paned_main" ).add2( @image_gallery )

                @image_gallery.signal_connect "selected" do |w, pos, status|
                    if status != 0
                        @select_window.add( @img_infos[pos] )

                        @pos_prev = @pos_cur
                        @pos_cur = pos
                        @img_prev = @img_cur
                        @img_cur = Gdk::Pixbuf.new( :file =>  global.media_mgr.media.repo.thumb_path( Storage::Md5sum.new(@img_infos[pos].id ) ) ).scale( @btn_add_range.allocation.width, @btn_add_range.allocation.width )
                        @img_range_2.pixbuf = @img_prev
                        @img_range_1.pixbuf = @img_cur
                    else
                        @select_window.remove( @img_infos[pos] )
                    end
                end

                @btn_add_range.signal_connect( "clicked" ) do
                    if  @pos_prev && @pos_cur
                        if @pos_cur < @pos_prev
                            tmp = @pos_cur
                            @pos_cur = @pos_prev
                            @pos_prev = tmp
                        end

                        @pos_prev.upto(@pos_cur) do |i|
                            global.selection.add( @img_infos[ i ].id )
                            @select_window.add( @img_infos[i] )
                        end

                        @image_gallery.refresh
                    end
                end

                @tv_time = @builder.get_object( "tv_time" )
                init_time( @tv_time )
                load_time( @tv_time )
                load_data( @tv_time.model.iter_first[1] )

                @cbo_album = @builder.get_object( "cbo_album" )

                global.populate_album_combobox(@cbo_album)

                @cbo_album.active = 0

                @cbo_album.signal_connect("changed") do
                    puts "album activite #{@cbo_album.active} : #{@cbo_album.active_iter[1]}"
                    global.db = global.media_mgr.db.album[:id=>@cbo_album.active_iter[1]].medias_dataset
                    load_time( @tv_time )
                    if @tv_time.model.iter_first.nil?
                        load_data( {:year=>0} )
                    else
                        load_data( @tv_time.model.iter_first[1] ) 
                    end
                    refresh
                end
            end

            def hide_checks
                @image_gallery.hide_checks
            end

            def show_checks
                @image_gallery.show_checks
            end

            def init_time(tv_time)
                render = Gtk::CellRendererText.new
                tv_time.insert_column(-1, "Time", render, "text"=>0)
                tv_time.signal_connect "row-activated" do |w,path,column,user_data|
                    load_data(w.model.get_iter(path)[1])
                    false
                end
            end

            def load_time( tv_time )
                ts_time = Gtk::TreeStore.new(String, Hash)
                db = global.db

                #puts "load_time"
                #db.day_count.group(:year).select_append{ sum(count).as(total) }.all.each do |yrec|
                db.group_and_count(:year).all.each do |yrec|
                    yiter = ts_time.append(nil)
                    yiter[0] = "%d年 (%d)" % [ yrec[:year], yrec[:count] ]
                    #puts "load year %s" % yiter[0]
                    yiter[1] = { :year=>yrec[:year] }
                    #db.day_count.where(:year=>yrec[:year]).group(:year, :month).select_append{ sum(count).as(total) }.all.each do |mrec|
                    db.where(:year=>yrec[:year]).group_and_count(:month).all.each do |mrec|
                        miter = ts_time.append(yiter)
                        miter[0] = "%d月 (%d)" % [ mrec[:month], mrec[:count] ]
                        miter[1] = { :year=>yrec[:year], :month=>mrec[:month] }
                        #db.day_count.where(:year=>mrec[:year], :month=>mrec[:month]).group(:year, :month, :day).select_append{ sum(count).as(total) }.all.each do |rec|
                        db.where(:year=>yrec[:year], :month=>mrec[:month]).group_and_count(:day).all.each do |rec|
                            #puts "%d/%d/%d : %d" % [ rec.year, rec.month, rec.day, rec[:total] ]
                            iter = ts_time.append(miter)
                            iter[0] = "%d日 (%d)" % [ rec[:day], rec[:count] ]
                            iter[1] = { :year=>yrec[:year], :month=>mrec[:month], :day=>rec[:day] }
                        end
                    end
                end

                tv_time.set_model( ts_time )

                tv_time.set_size_request 160, -1


                @page_ind = 0
            end

            def refresh
                if @cbo_album && ( @cbo_album.active != 0 )
                    @tv_time.expand_all
                end
                @image_gallery.refresh
            end


            def load_data(params)
                @img_infos = global.db.where(params).order_by(:create_time).all
                @image_gallery.img_infos = @img_infos
                refresh
            end


            def show
                @wnd_main.show_all
            end
        end
    end
end
