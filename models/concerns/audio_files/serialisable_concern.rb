module AudioFiles
  module Serialisable
    def to_h(options={})
      {
        id: id.to_s,
        name: name,
        translation: translation,
        status: status,
        translator: translator,
        public_file: file.gsub('/public', '').gsub('//','/'),
        duration: Time.at(duration).gmtime.strftime('%R:%S'),
        audio_folder: audio_folder.id
      }.merge!(options)
    end
    alias_method :prep_json, :to_h

    def to_json
      to_h.to_json
    end
  end
end
