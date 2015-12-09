gem 'test-unit'
require 'test/unit'
require 'stringio'
require 'ruiheng/conf'
Ruiheng::Conf.set_test(true)
require 'db'


module TestNeedFileSystem
    TMP_PATH = File.dirname(__FILE__) + '/../tmp/'
    SAMPLE_PATH = File.dirname(__FILE__) + '/samples/'
    SAMPLE_BAD_PATH = File.dirname(__FILE__) + '/samples-bad/'
    JPG_1 = SAMPLE_PATH + "1.jpg"
    JPG_1_MD5SUM = "ff76933f9f9f3dec11e157c971b776fc" 
    JPG_1_PATH = "ff/76/933f9f9f3dec11e157c971b776fc" 
    JPG_1_MAKE = "Motorola"
    JPG_1_MODEL = "MT810"
    JPG_1_SIZE = 481332

    MP4_1 = SAMPLE_PATH + "checkins/2011-09-02_10-06-24_917.mp4"
    MP4_1_MD5SUM = "bffed5b7ff2e1c6d48eb61f68b31fa29"
    MP4_1_PATH = "bf/fe/d5b7ff2e1c6d48eb61f68b31fa29"

    JpgInfo = Struct.new( :path, :md5sum, :id_path )

    JpgInfos = [ 
        JpgInfo.new( JPG_1, JPG_1_MD5SUM, JPG_1_PATH ),
        JpgInfo.new( SAMPLE_PATH + "2.jpg", "78d3bc69a697098013881d79801fe275", "78/d3/bc69a697098013881d79801fe275" ),
        JpgInfo.new( SAMPLE_PATH + "checkins/sub1/2011-09-10_17-27-01_361.jpg", "c16c6c7757bbe26f29b97e2e91670c51", "c1/6c/6c7757bbe26f29b97e2e91670c51" ),
        JpgInfo.new( SAMPLE_PATH + "checkins/2011-09-10_17-27-08_486.jpg", "819f4556a198ffc91f231c2fad63532a", "81/9f/4556a198ffc91f231c2fad63532a" ),
    ]

    def sample_path
        SAMPLE_PATH
    end

    def sample_bad_path
        SAMPLE_BAD_PATH
    end
    
    def setup_path(relative_path)
       path = TMP_PATH + relative_path 
       if File.exist? path
           FileUtils.rm_rf path
       end
       FileUtils.mkdir_p path
       path
    end
end
