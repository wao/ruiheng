module Ui
    module Gtk3
        module Image
            def self.draw_image( cr, pixbuf, width, height, rotate, keep_xy_ratio )
                cr.save do
                    if pixbuf
                        xscale = 1.0 * width / pixbuf.width
                        yscale = 1.0 * height / pixbuf.height
                        if keep_xy_ratio
                            tmp = xscale < yscale ? xscale : yscale
                            xscale = yscale = tmp
                            if ( pixbuf.width < pixbuf.height ) && ( width > height )
                                #xscale = xscale / 0.8
                            end
                        end
                        if rotate % 2 == 1
                            tmp = xscale
                            xscale = yscale
                            yscale = tmp
                        end
                        cr.translate( 0.5 * width, 0.5 * height )
                        cr.scale( xscale, yscale )
                        cr.rotate( rotate * 6.283 / 4 )
                        cr.set_source_pixbuf(pixbuf, - 0.5 * pixbuf.width, - 0.5 * pixbuf.height )
                        cr.paint
                    end
                end
            end
        end
    end
end
