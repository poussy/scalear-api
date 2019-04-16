class VimeoUpload < ApplicationRecord
    validates :vimeo_url ,:presence => true 
end
