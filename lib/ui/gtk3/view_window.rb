module Ui
    module Gtk3
        class ViewWindow
            attr_reader :global

            def initialize(global, img_infos,pos)
                @global = global
                @img_infos = img_infos 
                @pos = pos
                @builder = Gtk::Builder.new
                @builder.add_from_file( File.dirname(__FILE__) + "/../../../res/glade/viewer.glade" )
                @wnd_view = @builder.get_object( "wnd_view" )
                @wnd_view.override_background_color( :normal, Gdk::RGBA.parse( "#000000" ) )
                @da_view = @builder.get_object( "da_view" )
                @lb_view = @builder.get_object( "lb_view_detail" )
                @lb_view.override_background_color( :normal, Gdk::RGBA.parse( "#000000" ) )

                #@wnd_view.set_size_request 800, 600

                @da_view.signal_connect( "draw" ) do |w,cr|
                    pixbuf = get_pixbuf()
                    width = w.allocation.width
                    height = w.allocation.height
                    cr.save do
                        #puts "%d:%d" % [ width, height ]
                        cr.set_source_color(Gdk::Color.new(0, 0, 0))
                        cr.gdk_rectangle(Gdk::Rectangle.new(0, 0, width, height))
                        cr.fill
                    end

                    if pixbuf 
                        Image.draw_image( cr, pixbuf, w.allocation.width, w.allocation.height, @img_infos[@pos].rotate, true )
                    end
                    true
                end

                @builder.get_object('tb_next').signal_connect('clicked') do |w|
                    if @pos < @img_infos.length - 1
                        @pos += 1
                        refresh
                    end
                end

                @builder.get_object('tb_prev').signal_connect('clicked') do |w|
                    if @pos > 0
                        @pos -= 1
                        refresh
                    end
                end

                @builder.get_object('tb_rotate').signal_connect('clicked') do |w|
                    img_info = @img_infos[@pos]
                    img_info.rotate += 1
                    if img_info.rotate >= 4
                        img_info.rotate = 0
                    end
                    global.media_mgr.media.db[img_info.id].update( :rotate=>img_info.rotate )
                    refresh
                end

                @wnd_view.maximize

                refresh
            end

            DetailTemplate = <<__END__
Date: %s
Time: %s

Camear:
    Maker: %s
    Model: %s

Tags:
    %s

Albums:
   %s

Orignal Name:
    %s
__END__

            def refresh
                img_info = @img_infos[@pos]
                @lb_view.text = DetailTemplate % [ img_info.create_time.strftime( "%Y/%m/%d" ), img_info.create_time.strftime( "%H:%M" ), img_info.make, img_info[:model], img_info.tags.map{|item|item.text}.join("      \n"), img_info.albums.map{|item|item.name}.join("\n"), File.basename( img_info.file_path ) ]
                @da_view.queue_draw
            end

            def show
                @wnd_view.show_all
            end

            def hide
                @wnd_view.hide
            end

            def get_pixbuf()
                if @pos < @img_infos.length
                    Gdk::Pixbuf.new( :file =>  global.media_mgr.media.repo.media_path( Storage::Md5sum.new(@img_infos[@pos].id ) ) ) 
                else 
                    nil
                end
            end
        end
    end
end
