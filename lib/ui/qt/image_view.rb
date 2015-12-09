require 'Qt'

class MyImageWidget < Qt::Widget
    attr_accessor :custom_data

    def initialize(parent)
        super(parent)
        backgroundRole = Qt::Palette::Base
        #setSizePolicy(Qt::SizePolicy::Ignored, Qt::SizePolicy::Ignored)
        #scaledContents = true
        @b_mouse_down = false
        @custom_data = -1
        @pixmap = nil
    end

    def paintEvent(event)
        if @pixmap	    
            painter = Qt::Painter.new
            painter.begin(self)
            painter.draw_pixmap( 0, 0, width, height, @pixmap, 0, 0, @pixmap.width, @pixmap.height )
            painter.send :end
        end
    end

    def pixmap=(v)
        @pixmap = v
        update
    end

    def mousePressEvent(event)
        @b_mouse_down = true
    end

    def mouseReleaseEvent(event)
        if @b_mouse_down
            #emit onClick(@tag)
        end

        @b_mouse_down = false
    end

    def enterEvent(event)
        @b_mouse_down = false
    end

    def mouseDoubleClickEvent(event)
        if event.button() == Qt::LeftButton
            parent.emit_onClick(@custom_data)
        end
    end
end


class MyImageView < Qt::Widget
    signals "onClick(int)"

    def initialize(parent)
        super(parent)
        setSizePolicy(Qt::SizePolicy::Preferred, Qt::SizePolicy::Preferred)

        @l_viewer = Qt::VBoxLayout.new
        @w_image = MyImageWidget.new(self)
        @w_image.setSizePolicy(Qt::SizePolicy::Preferred, Qt::SizePolicy::Preferred)
        #@w_image = Qt::Widget.new(self)
        #Qt::CheckBox.new(label)
        #@l_images.addWidget( label, y, x )
        @l_viewer.addWidget( @w_image )
        @lbl_tag = Qt::Label.new(self)
        @lbl_tag.setSizePolicy(Qt::SizePolicy::Preferred, Qt::SizePolicy::Fixed)
        @l_viewer.addWidget( @lbl_tag )
    end

    def emit_on_click(v)
        emit onClick(v)
    end

    def pixmap=(v)
        @w_image.pixmap = v
    end

    def text=(v)
        @lbl_tag.text = v
    end

    def custom_data=(v)
        @w_image.custom_data = v
    end
end
