module HelperUtils
  
  def sanitize_filename(filename)
    return filename.gsub /[^a-z0-9\-]+/i, '_'
  end

end