class ShoesToolKit
  def self.calculate_list_box_width(str_array)
    (str_array.map { |el| (el.length + el.length) / (str_array.size) }.inject(0) do |sum, x| sum + x  end) * 10
  end

  def self.str_value_exist?(value)
    debug("value: #{value.inspect}")
    (value == nil || value == "" || value == " ")
  end
end

class Zipper
  def self.zip(dir, zip_dir, remove_after = false)
    Zip::ZipFile.open(zip_dir, Zip::ZipFile::CREATE)do |zipfile|
      Find.find(dir) do |path|
        Find.prune if File.basename(path)[0] == ?.
        dest = /#{dir}\/(\w.*)/.match(path)
        # Skip files if they exists
        begin
          zipfile.add(dest[1],path) if dest
        rescue Zip::ZipEntryExistsError
        end
      end
    end
    FileUtils.rm_rf(dir) if remove_after
  end

  def self.unzip(zip, unzip_dir, remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
    FileUtils.rm(zip) if remove_after
  end

  def self.open_one(zip_source, file_name)
    Zip::ZipFile.open(zip_source) do |zip_file|
      zip_file.each do |f|
        next unless "#{f}" == file_name
        return f.get_input_stream.read
      end
    end
    nil
  end
end

Shoes.setup do
  gem 'zip'
  require("fileutils")
  require("find")
  require("date")
  require("zip")
end

Shoes.app(width: 350, height: 250, title: "Ruby Zipper", resizable: false) do 

  OPERATIONS = ["Zip", "Unzip"].freeze

  flow left: 65, top: 20 do 
    @file_path_str = edit_line(width: 250, right: 154)

    button("...", width: 60, right: 85) do 
      @selected_dir = ask_open_folder
      @file_path_str.text = @selected_dir

      if @selected_dir 
        @dir_contents = Dir.entries(@selected_dir)
        @dir_contents_size = @dir_contents.size
        @zip_file_name = "#{File.basename(@selected_dir)}_#{Date.today.strftime("%Y%m%d").to_s}.zip"
        
        debug(@dir_contents)
        debug("Files Found: #{@dir_contents_size}")
      end
    end

    flow do 
      @operation = OPERATIONS.first

      lb_width = ShoesToolKit.calculate_list_box_width(OPERATIONS)

      para "Operation: "

      list_box(items: OPERATIONS, width: lb_width) do |op|
        @operation = op.text
      end

    end

    stack right: 54, top: 80 do 
      @zip_progress = progress(width: 330)

      flow do 
        button("Start", width: 95, left: 112) do 
          if ShoesToolKit.str_value_exist?(@selected_dir)
            alert("You must select a directory or file to zip before starting.", title: "Could not start operation:")
          else
            case @operation
            when "Zip"
              #Thread.new { Zipper.zip(File.join(@selected_dir), File.join(ENV["HOME"], "Desktop/#{@zip_file_name}")) }.join
              Zipper.zip(File.join(@selected_dir), File.join(ENV["HOME"], "Desktop/#{@zip_file_name}"))
              animate do |i|
                @zip_progress.fraction = (@dir_contents_size % Zipper.progress ) * 100
              end
            when "Unzip"
              alert("unzip operation selected!")
            else
              alert("you must select an operation!")
            end
          end
        end
      end

    end
  end # end flow
end