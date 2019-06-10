module HelperUtils
  
  def sanitize_filename(filename)
    return filename.gsub /[^a-z0-9\-]+/i, '_'
  end

  def check_and_encode_UTF8(text)
    text = text.force_encoding("UTF-8") if text.encoding.name != "UTF-8"
    return text  
  end  
end