require 'ui/gtk3/image_gallery'

module Ui
    module Gtk3
        class SelectionWindow
            attr_reader :global

            def initialize(global)
                @global = global
                builder = global.builder
                @wnd = builder.get_object("wnd_selection")
                @image_gallery = ImageGallery.new(global, 4,4, false)
                @img_infos = []
                @image_gallery.img_infos = @img_infos


                builder.get_object("box_select_main").pack_start @image_gallery, :fill=>true, :expand=>true

                builder.get_object("act_select_unselect").signal_connect "activate" do |w|
                end
                builder.get_object("act_select_add_tag").signal_connect "activate" do |w|
                    add_tag
                end
                builder.get_object("act_select_add_album").signal_connect "activate" do |w|
                    add_album
                end
                builder.get_object("act_select_export").signal_connect "activate" do |w|
                    export_selections
                end
            end

            def add_album
                show_entry_dialog( "Add Tag to Selected Pictures", "Album" ) do |input_text|
                    puts "input #{input_text}"
                    global.media_mgr.add_album_by_id( @img_infos, input_text )
                end
            end

            def add_tag
                show_entry_dialog( "Add Tag to Selected Pictures", "Tag" ) do |input_text|
                    global.media_mgr.add_tag( @img_infos, input_text )
                end
            end

            def show_entry_dialog( title, entry_name )
                dialog = Gtk::Dialog.new(:title=>'title',
                                         :parent=>@wnd,
                                         :flags=>Gtk::Dialog::Flags::MODAL | Gtk::Dialog::Flags::DESTROY_WITH_PARENT,
                                         :buttons=>[[Gtk::Stock::OK, Gtk::ResponseType::OK], ["Cancel", Gtk::ResponseType::CANCEL]]
                                        )

                hbox = Gtk::Box.new(:horizontal, 0)
                hbox.set_border_width(8)
                dialog.child.pack_start(hbox, :expand => false, :fill => false, :padding => 0)

                stock = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::IconSize::DIALOG)
                hbox.pack_start(stock, :expand => false, :fill => false, :padding => 0)

                table = Gtk::Table.new(2, 1, false)
                table.set_row_spacings(4)
                table.set_column_spacings(4)
                hbox.pack_start(table, :expand => true, :fill => true, :padding => 0)
                label = Gtk::Label.new(entry_name, true)
                table.attach_defaults(label,
                                      0, 1, 0, 1)
                local_entry1 = Gtk::ComboBox.new
                global.populate_album_combobox(local_entry1)
                table.attach_defaults(local_entry1, 1, 2, 0, 1)
                label.set_mnemonic_widget(local_entry1)

                hbox.show_all
                response = dialog.run

                puts response

                if response == Gtk::ResponseType::OK.to_int
                    yield local_entry1.active_iter[1]
                end
                dialog.destroy
            end

            def export_selections
                dlg_select_path = Gtk::FileChooserDialog.new( :title=>"Export images to a folder", :action=>:select_folder, :buttons=>[[Gtk::Stock::CANCEL, :cancel], ["Export", :accept] ] )

                begin
                    ret = dlg_select_path.run
                    puts ret
                    if ret == Gtk::ResponseType::ACCEPT
                        puts dlg_select_path.filename
                        if File.directory? dlg_select_path.filename
                            @img_infos.each do |img|
                                puts img.id
                                global.media_mgr.media.repo.copy( Storage::Md5sum.new(img.id), dlg_select_path.filename + "/" + File.basename( img.file_path ) )
                            end
                        else
                            raise "#{@dlg_select_path.filename} is not a directory!"
                        end
                    end


                    dlg_select_path.destroy
                end
            end

            def add(image_info)
                if !@img_infos.include? image_info
                    @img_infos.unshift(image_info)
                    @image_gallery.update_image_infos
                end
            end

            def remove(image_info)
                @img_infos.delete(image_info)
                @image_gallery.update_image_infos
            end

            def hide
                @wnd.hide
                @img_infos.clear
                global.selection.clear
                @image_gallery.update_image_infos
            end

            def show
                @wnd.show_all
            end
        end
    end
end
