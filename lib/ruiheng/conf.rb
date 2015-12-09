module Ruiheng
    class Conf
        @@is_test = false

        def self.set_test(value)
            @@is_test = value
        end

        def self.test?
            if ENV["IN_UNIT_TEST" ] == "true"
                true
            else
                @@is_test
            end
        end
    end
end
