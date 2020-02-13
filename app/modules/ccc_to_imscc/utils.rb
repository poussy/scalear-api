require_relative  "zip_file_generator"
module CccToImscc::Utils 
    def convert_ccc_to_imscc(cc_path)
        puts "--------------cc_path-------------"
        puts cc_path
        #rename to zip 
        cc_path_renamed_to_zip=rename_imscc_folder(cc_path)
        puts "--------cc_path_renamed_to_zip--------"
        puts cc_path_renamed_to_zip

        #unzip cc package
        orgiginal_folder = unzip_folder(cc_path_renamed_to_zip)
        puts "-------------orgiginal_folder------------------"
        puts orgiginal_folder
        #copy hierarchy
        new_folder = copy_dir(orgiginal_folder)
        puts "------------new_folder-------------------"
        puts new_folder
        #rewrite content into the new folder

        #zip the new folder 
        new_folder_zipped = zip_folder(new_folder)
        puts "-------------new_folder_zipped------------------"
        puts new_folder_zipped

        #rename folder to imscc
        new_folder_imscced = rename_zipped_folder(new_folder_zipped)
        puts "-----------new_folder_imscced--------------------"
        puts new_folder_imscced

        return new_folder_imscced
    end    
    def copy_dir(from)
        to = from+"-cpd"
        FileUtils.copy_entry from, to
        return to
    end
    def zip_folder(from)
        directory_to_zip = from
        output_file_path = from[0...-1]+".zip"
        zf = ZipFileGenerator.new(directory_to_zip, output_file_path)
        zf.write()
        return  output_file_path
    end
    def rename_zipped_folder(to)
        tmp = to[0...-4]+"-ims.imscc"
        File.rename(to, tmp)
        return tmp
    end    
    def rename_imscc_folder(cc_path)
        tmp = cc_path[0...-5]+"zip"
        File.rename(cc_path, tmp)
        return tmp
    end    
    def unzip_folder (from)
        destination = from[0...-4]
        Zip::ZipFile.open(from) { |zip_file|
         zip_file.each { |f|
           f_path=File.join(destination, f.name)
           FileUtils.mkdir_p(File.dirname(f_path))
           zip_file.extract(f, f_path) unless File.exist?(f_path)
         }
        }
        return destination
    end         
end

