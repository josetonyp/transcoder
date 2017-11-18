module Downloadable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

  end

  def zipfile_name
    "#{AudioFolder::OUTTXTFOLDER}/#{name.gsub(/^[^\/]*?\//, "")}.zip"
  end

  def audio_wav_folder
    "#{AudioFolder::OUTFOLDER}/#{id}"
  end

  def audio_files_folder
    "#{AudioFolder::OUTTXTFOLDER}/#{id}"
  end

  def prepare_to_download
    FileUtils.mkdir_p audio_files_folder
    audio_files.map(&:save_file)
  end

  def build
    self.downloaded = true
    save
    prepare_to_download
    File.delete( zipfile_name ) if File.exist?( zipfile_name)

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      Dir.glob( "#{audio_files_folder}/*" ).each do |filename|
        # Two arguments:
        # - The name of the file as it will appear in the archive
        # - The original file, including the path to find it
        zipfile.add(filename.gsub("#{audio_files_folder}/",""),filename)
      end
    end
  end
end
