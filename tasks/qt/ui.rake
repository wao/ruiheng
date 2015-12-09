task "qt:ui:make" do
    sh 'rbuic4 res/qtdesigner/main_window.ui > lib/ui/main_window.rb'
end
