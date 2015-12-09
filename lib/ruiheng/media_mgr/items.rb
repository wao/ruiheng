require 'ruiheng/sync/items'
require 'null_console'

module Ruiheng
    class MediaMgr
        class Items
            include Sync::Items

            attr_reader :db, :repo
            def initialize(db,repo,console=nil)
                @console = console || NullLogger.new
                @db = db
                @repo = repo
            end
        end
    end
end
