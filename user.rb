class User < ActiveRecord::Base
    serialize :notifications, Array
end

class Club < ActiveRecord::Base
end

class Admin < ActiveRecord::Base
end

class Cookie < CGI::Cookie
end
