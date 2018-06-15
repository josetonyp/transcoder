module Importable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # import_batch(batch: Batch.last)
    # import_batch(batch: Batch.last, debug: true)
    # import_batch(batch: Batch.last, debug: true, text: true)
    # import_batch(batch: Batch.last, text: true)
    def import_batch(options={})
      ap options
      Dir.glob("#{AudioFolder::INFOLDER}/*.zip").each do |file|
        import(options.merge({file: file}))
      end
      AudioFolder.remove_indexes
      AudioFolder.create_indexes
      AudioFile.remove_indexes
      AudioFile.create_indexes
    end

    def import(options={})
      ap options
      digest(options.fetch(:file)).tap do |folder|
        ap "Importing #{options.fetch(:file)} folder ..."
        folder.digest_audio_files(options)
        folder.update_folder_duration
        folder.digest_text_files if options.fetch(:text, false)
        folder.destroy_wav_files_folder
        if options.fetch(:batch, nil)
          batch = options.fetch(:batch)
          folder.batch = batch
          folder.save
          batch.update_folders_count
        end
      end
    end

    def digest(file)
      importer = Importer.new(file)
      importer.unzip.tap do |imported|
        factory(imported.sanitized_name).tap do |folder|
          folder.update_attributes(duration: nil)
          folder.imported! unless folder.started?
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

  def digest_audio_files(options={})
    Dir.glob("#{wav_files_folder}/*.wav").each do |wfile|
      if options.fetch(:debug, nil)
        ap "digesting #{wfile}"
      end
      file = digest_wav(wfile, options)
      AudioFile.upfind(Sanitize::base(file), self).waveme( file )
    end
  end

  def digest_text_files(options={})
    Dir.glob("#{wav_files_folder}/*.txt").each do |tfile|
      AudioFile.upfind( Sanitize::base( tfile.gsub(/.txt$/, '') ), self).txtme( Sanitize::clear_empty_lines(File.read(tfile)) )
    end
  end

  # Instance methods
  def digest_wav( wav_file, options={})
    if options.fetch(:debug, nil)
      ap "Coping #{wav_file} to #{audio_wav_folder}"
    end
    FileUtils.cp(wav_file,audio_wav_folder)
    "#{audio_wav_folder}/#{Sanitize::base(wav_file)}"
  end

  def update_folder_duration
    self.duration = audio_files.inject(0.0){|total,audio| total.to_f + audio.duration.to_f }
    ap duration
    save
  end
end
