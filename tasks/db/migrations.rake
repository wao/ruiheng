task "db:test:migration" do
    rm_f "tmp/data/meta.db"
    sh "sequel -m db/migrations sqlite://./tmp/data/meta.db"
end

task "db:migration" do
    rm_f "data/meta.db"
    sh "sequel -m db/migrations sqlite://./data/meta.db"
end
