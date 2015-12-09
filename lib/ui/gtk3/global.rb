require 'gtk3'
require 'ruiheng/media_mgr'
require 'storage'
require 'ui/gtk3/image_gallery'
require 'ui/gtk3/view_window'
require 'ui/gtk3/main_window'

class Global

    SubGlobal = Struct.new :media_mgr, :selection, :db do
        def builder
            if @builder.nil?
                @builder = Gtk::Builder.new
                @builder.add_from_file( File.dirname(__FILE__) + "/../../../res/glade/main.glade" )
            end
            @builder
        end

        def populate_album_combobox(cbo_album)
            album_model = Gtk::ListStore.new(String,String)
            media_mgr.db.album.all.each do |album|
                iter = album_model.append
                iter[0] = album.name
                iter[1] = album.id
            end

            cbo_album.model = album_model
            album_render = Gtk::CellRendererText.new
            cbo_album.pack_start(album_render, true)
            cbo_album.set_attributes(album_render, :text=>0)
            cbo_album
        end

    end

    attr_reader :builder, :media_mgr

    def initialize(repo_path)
        @media_mgr = Ruiheng::MediaMgr.new( repo_path )
    end

    def selection
        @selection ||= Set.new
    end


    def self.inst
        @inst
    end

    def self.create_inst(repo_path)
        @inst = Global.new(repo_path)
    end

    def run
        Gtk.init
        @main_window = Ui::Gtk3::MainWindow.new(SubGlobal.new(media_mgr, selection, media_mgr.default_album.medias_dataset))
        @main_window.show
        @main_window.hide_checks
        Gtk.main
    end
end

