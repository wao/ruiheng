require 'erb'
require 'logger'

module Ui
    module Html
        class Generator
            def initialize(mgr,dest_path)
                @mgr = mgr
                @dest_path = dest_path
                if !File.exist? @dest_path
                    FileUtils.mkdir_p @dest_path
                end
                @logger = Logger.new($stderr)
            end

            def html_filename( year, month, day )
                "%s/%04d-%02d-%02d.html" % [ @dest_path, year, month, day ]
            end

            NavNode = Struct.new( :prompt, :value, :children ) do
                def first_child
                    self.children[ self.children.keys.sort.first ]
                end

                def each_child
                    self.children.keys.sort.each do |key|
                        yield self.children[key]
                    end
                end
            end

            def fetch_nav_data
                @years = {}
                class << @years
                    def first_child
                        self[ self.keys.sort.first ]
                    end

                    def each_child
                        self.keys.sort.each do |key|
                            yield self[key]
                        end
                    end
                end

                puts @years.first_child

                @mgr.db.time_summary do |rec_type, prompt, value|
                    case rec_type
                    when :year
                        @years[value[:year]]=NavNode.new( prompt, value, {})
                    when :month
                        @years[value[:year]].children[value[:month]] = NavNode.new( prompt, value, {})
                    when :day
                        @years[value[:year]].children[value[:month]].children[value[:day]] = NavNode.new( prompt, value, {})
                    end
                end
            end

            def generate
                fetch_nav_data

                @mgr.db.time_summary do |rec_type, prompt, value|
                    if rec_type == :day
                        print 13.chr
                        print "Generate html for %04d/%02d/%02d" % [ value[:year], value[:month], value[:day] ]
                        File.write( html_filename( value[:year], value[:month], value[:day] ), generate_sub_page( value[:year], value[:month], value[:day] ) )
                    end
                end
            end

            def sub_page_template
                File.read( File.dirname( __FILE__ ) + "/../../../res/html/template/sub_page.erb" )
            end

            def nav_template
                File.read( File.dirname( __FILE__ ) + "/../../../res/html/template/nav.erb" )
            end

            def content_template
                File.read( File.dirname( __FILE__ ) + "/../../../res/html/template/content.erb" )
            end

            def generate_sub_page(year,month,day)
                @year = year
                @month = month
                @day = day
                
                @sub_page_render ||= ERB.new(sub_page_template)
                @sub_page_render.result(binding)
            end

            def nav
                @nav_render ||= ERB.new(nav_template)
                @nav_render.result(binding)
            end

            def content
                @content_render ||= ERB.new(content_template)
                @content_render.result(binding)
            end
        end
    end
end
