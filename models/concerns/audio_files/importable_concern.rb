module AudioFiles
  module Importable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
    end

    def file_name
      "#{OUTFOLDER}/#{audio_folder.id.to_s}/#{name}.txt"
    end

    def save_file
      File.delete(file_name) if File.exists?(file_name)
      File.write(file_name, translation)
    end

    def waveme( outfile )
      wave = WaveInfo.new(outfile)
      update_attributes!( file: "/#{outfile}", duration: wave.duration)
      print "."
      self
    end

    def txtme( text )
      update_attributes!( translation: text.strip)
      next! unless translated?
      print "-"
      self
    end
  end
end
