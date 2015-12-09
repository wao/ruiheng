=begin
** Form generated from reading ui file 'main_window.ui'
**
** Created: Fri Jul 18 17:59:35 2014
**      by: Qt User Interface Compiler version 4.8.4
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_MainWindow
    attr_reader :centralwidget
    attr_reader :horizontalLayout_2
    attr_reader :splitter
    attr_reader :tv_time
    attr_reader :layoutWidget
    attr_reader :horizontalLayout
    attr_reader :w_images_holder
    attr_reader :verticalLayout_3
    attr_reader :stack_main
    attr_reader :page
    attr_reader :verticalLayout_2
    attr_reader :horizontalLayout_3
    attr_reader :verticalLayout
    attr_reader :w_images
    attr_reader :lbl_navigator
    attr_reader :verticalScrollBar
    attr_reader :page_2
    attr_reader :verticalLayout_4
    attr_reader :lbl_big_image
    attr_reader :btn_back
    attr_reader :menubar
    attr_reader :statusbar

    def setupUi(mainWindow)
    if mainWindow.objectName.nil?
        mainWindow.objectName = "mainWindow"
    end
    mainWindow.resize(1291, 977)
    @centralwidget = Qt::Widget.new(mainWindow)
    @centralwidget.objectName = "centralwidget"
    @horizontalLayout_2 = Qt::HBoxLayout.new(@centralwidget)
    @horizontalLayout_2.objectName = "horizontalLayout_2"
    @splitter = Qt::Splitter.new(@centralwidget)
    @splitter.objectName = "splitter"
    @splitter.orientation = Qt::Horizontal
    @tv_time = Qt::TreeView.new(@splitter)
    @tv_time.objectName = "tv_time"
    @sizePolicy = Qt::SizePolicy.new(Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding)
    @sizePolicy.setHorizontalStretch(0)
    @sizePolicy.setVerticalStretch(0)
    @sizePolicy.heightForWidth = @tv_time.sizePolicy.hasHeightForWidth
    @tv_time.sizePolicy = @sizePolicy
    @splitter.addWidget(@tv_time)
    @layoutWidget = Qt::Widget.new(@splitter)
    @layoutWidget.objectName = "layoutWidget"
    @horizontalLayout = Qt::HBoxLayout.new(@layoutWidget)
    @horizontalLayout.objectName = "horizontalLayout"
    @horizontalLayout.setContentsMargins(0, 0, 0, 0)
    @w_images_holder = Qt::Widget.new(@layoutWidget)
    @w_images_holder.objectName = "w_images_holder"
    @w_images_holder.minimumSize = Qt::Size.new(0, 0)
    @verticalLayout_3 = Qt::VBoxLayout.new(@w_images_holder)
    @verticalLayout_3.objectName = "verticalLayout_3"
    @stack_main = Qt::StackedWidget.new(@w_images_holder)
    @stack_main.objectName = "stack_main"
    @page = Qt::Widget.new()
    @page.objectName = "page"
    @verticalLayout_2 = Qt::VBoxLayout.new(@page)
    @verticalLayout_2.objectName = "verticalLayout_2"
    @horizontalLayout_3 = Qt::HBoxLayout.new()
    @horizontalLayout_3.objectName = "horizontalLayout_3"
    @verticalLayout = Qt::VBoxLayout.new()
    @verticalLayout.objectName = "verticalLayout"
    @w_images = Qt::Widget.new(@page)
    @w_images.objectName = "w_images"
    @w_images.minimumSize = Qt::Size.new(800, 600)

    @verticalLayout.addWidget(@w_images)

    @lbl_navigator = Qt::Label.new(@page)
    @lbl_navigator.objectName = "lbl_navigator"
    @sizePolicy1 = Qt::SizePolicy.new(Qt::SizePolicy::Preferred, Qt::SizePolicy::Fixed)
    @sizePolicy1.setHorizontalStretch(0)
    @sizePolicy1.setVerticalStretch(0)
    @sizePolicy1.heightForWidth = @lbl_navigator.sizePolicy.hasHeightForWidth
    @lbl_navigator.sizePolicy = @sizePolicy1
    @font = Qt::Font.new
    @font.pointSize = 20
    @lbl_navigator.font = @font
    @lbl_navigator.lineWidth = 2
    @lbl_navigator.textFormat = Qt::RichText
    @lbl_navigator.alignment = Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter
    @lbl_navigator.margin = 0

    @verticalLayout.addWidget(@lbl_navigator)


    @horizontalLayout_3.addLayout(@verticalLayout)

    @verticalScrollBar = Qt::ScrollBar.new(@page)
    @verticalScrollBar.objectName = "verticalScrollBar"
    @verticalScrollBar.orientation = Qt::Vertical

    @horizontalLayout_3.addWidget(@verticalScrollBar)


    @verticalLayout_2.addLayout(@horizontalLayout_3)

    @stack_main.addWidget(@page)
    @page_2 = Qt::Widget.new()
    @page_2.objectName = "page_2"
    @verticalLayout_4 = Qt::VBoxLayout.new(@page_2)
    @verticalLayout_4.objectName = "verticalLayout_4"
    @lbl_big_image = Qt::Label.new(@page_2)
    @lbl_big_image.objectName = "lbl_big_image"
    @sizePolicy2 = Qt::SizePolicy.new(Qt::SizePolicy::Ignored, Qt::SizePolicy::Ignored)
    @sizePolicy2.setHorizontalStretch(0)
    @sizePolicy2.setVerticalStretch(0)
    @sizePolicy2.heightForWidth = @lbl_big_image.sizePolicy.hasHeightForWidth
    @lbl_big_image.sizePolicy = @sizePolicy2
    @lbl_big_image.scaledContents = true

    @verticalLayout_4.addWidget(@lbl_big_image)

    @btn_back = Qt::PushButton.new(@page_2)
    @btn_back.objectName = "btn_back"

    @verticalLayout_4.addWidget(@btn_back)

    @stack_main.addWidget(@page_2)

    @verticalLayout_3.addWidget(@stack_main)


    @horizontalLayout.addWidget(@w_images_holder)

    @splitter.addWidget(@layoutWidget)

    @horizontalLayout_2.addWidget(@splitter)

    mainWindow.centralWidget = @centralwidget
    @menubar = Qt::MenuBar.new(mainWindow)
    @menubar.objectName = "menubar"
    @menubar.geometry = Qt::Rect.new(0, 0, 1291, 25)
    mainWindow.setMenuBar(@menubar)
    @statusbar = Qt::StatusBar.new(mainWindow)
    @statusbar.objectName = "statusbar"
    mainWindow.statusBar = @statusbar

    retranslateUi(mainWindow)

    Qt::MetaObject.connectSlotsByName(mainWindow)
    end # setupUi

    def setup_ui(mainWindow)
        setupUi(mainWindow)
    end

    def retranslateUi(mainWindow)
    mainWindow.windowTitle = Qt::Application.translate("MainWindow", "MainWindow", nil, Qt::Application::UnicodeUTF8)
    @lbl_navigator.text = Qt::Application.translate("MainWindow", "<a style=\"text-decoration:none;color:red;\" href=\"prev\">&lt;</a>&nbsp;&nbsp;<a href=\"next\">&gt;</a>", nil, Qt::Application::UnicodeUTF8)
    @lbl_big_image.text = Qt::Application.translate("MainWindow", "TextLabel", nil, Qt::Application::UnicodeUTF8)
    @btn_back.text = Qt::Application.translate("MainWindow", "PushButton", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(mainWindow)
        retranslateUi(mainWindow)
    end

end

module Ui
    class MainWindow < Ui_MainWindow
    end
end  # module Ui

