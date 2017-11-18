module Importable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def import
      threads=[]
      Dir.glob("#{INFOLDER}/*.zip").each do |file|
        threads << Thread.new {
          Importer.new(file).unzip.tap do |imported|

            factory(imported.sanitized_name, imported.wavs.empty?).tap do |folder|
              if imported.wavs.empty?
                imported.txts.each do |tfile|
                  AudioFile.upfind( Sanitize::base( tfile.first.gsub(/.txt$/, '') ), folder )
                    .txtme( File.read(tfile).strip )
                end
              else
                imported.wavs.each do |wfile|
                  file = folder.digest_wav(wfile)
                  AudioFile.upfind( Sanitize::base(file), folder )
                    .waveme( file )
                    .txtme( File.read("#{wfile}.txt").strip )
                end
              end
              folder.imported!
              folder.update_folder_duration
            end

          end.destroy
        }
      end
      threads.map(&:join)
    end

    def digest(file)
      importer = Importer.new(file)
      return unless factory(importer.sanitized_name).imported?
      importer.unzip.tap do |imported|
        factory(imported.sanitized_name, imported.wavs.empty?).tap do |folder|
          folder.audio_files.destroy_all
          folder.imported!
        end
      end
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
