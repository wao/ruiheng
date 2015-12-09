require 'Qt'

module Qt
    class FlowWidget < Widget

        signals 'sizeChanged()'

        def initialize(parent=nil)
            super(parent)
        end

        def resizeEvent(event)
            super(event)
            emit sizeChanged()
        end
    end
end
