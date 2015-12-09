require 'securerandom'
require 'handshake'

module Storage
    class Uuid
        include Handshake
        include Comparable


        attr_reader :uuid

        #contract any?( [String], [nil] )=>anything
        before do |uuid=nil|
        if !uuid.nil?
            uuid.is_a? String
        end
        end
        def initialize(uuid=nil)
            @uuid = uuid 
            @uuid = SecureRandom.uuid.to_s if @uuid.nil?
        end

        contract []=>String
        def to_s
            @uuid
        end

        def to_path
            @uuid.gsub( "-", File::SEPARATOR )
        end

        def <=>(value)
            puts "come here"

            @uuid <=> @value.uuid
        end
    end

    class Md5sum
        include Handshake

        contract [String]=>anything
        def initialize(md5sum)
            @md5sum = md5sum
        end

        def self.from_file( file_path )
            self.new( Digest::MD5.hexdigest(File.read(file_path)) )
            #self.new( `md5sum #{file_path}`.split(/\s+/)[0] )
        end

        contract [String]=>Md5sum
        def self.from_string( string_value )
            self.new( Digest::MD5.hexdigest(string_value ) )
        end

        contract []=>String
        def to_s
            @md5sum
        end

        def to_path
            String.new(@md5sum).insert( 4, File::SEPARATOR ).insert( 2, File::SEPARATOR )
        end
    end
end

class Time
    def to_path
        strftime( "%Y/%m/%d/%H_%M_%S" )
    end
end

