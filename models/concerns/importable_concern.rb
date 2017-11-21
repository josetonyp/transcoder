module Importable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def import_batch(text=false)
      Dir.glob("#{AudioFolder::INFOLDER}/*.zip").each do |file|
        import(file, text)
      end
      AudioFolder.remove_indexes
      AudioFolder.create_indexes
      AudioFile.remove_indexes
      AudioFile.create_indexes
    end

    def import(file, text=false)
      digest(file).tap do |folder|
        if folder.nil?
          ap "This #{file} folder is already imported and translated"
        else
          ap "Importing #{file} folder ..."
          folder.digest_audio_files
          folder.update_folder_duration
          folder.digest_text_files if text
          folder.destroy_wav_files_folder
        end
      end
    end

    def digest(file)
      importer = Importer.new(file)
      return unless factory(importer.sanitized_name).imported?
      importer.unzip.tap do |imported|
        factory(imported.sanitized_name).tap do |folder|
          folder.audio_files.destroy_all
          folder.update_attributes(duration: nil)
          folder.imported!
        end
      end
      factory(importer.sanitized_name)
    end

    def factory( name, only_text = false )
      folder = unless where( name: name).exists?
          create( name: name )
       else
          where(name: name).first
       end
      unless only_text
        FileUtils.rm_rf(folder.audio_wav_folder)
        FileUtils.mkdir_p(folder.audio_wav_folder)
      end
      folder
    end
  end

  def wav_files_folder
    "#{APPROOT}/folders/#{name}"
  end

  def destroy_wav_files_folder
    FileUtils.rm_rf(wav_files_folder) if Dir.exists?(wav_files_folder)
  end

  def digest_audio_files
    Dir.glob("#{wav_files_folder}/*.wav").each do |wfile|
      file = digest_wav(wfile)
      AudioFile.upfind(Sanitize::base(file), self).waveme( file )
    end
  end

  def digest_text_files
    Dir.glob("#{wav_files_folder}/*.txt").each do |tfile|
      AudioFile.upfind( Sanitize::base( tfile.gsub(/.txt$/, '') ), self).txtme( Sanitize::clear_empty_lines(File.read(tfile)) )
    end
  end

  # Instance methods
  def digest_wav( wav_file )
    FileUtils.cp(wav_file,audio_wav_folder)
    "#{audio_wav_folder}/#{Sanitize::base(wav_file)}"
  end

  def update_folder_duration
    self.duration = audio_files.inject(0.0){|total,audio| total.to_f + audio.duration.to_f }
    ap duration
    save
  end
end
