module Serialisable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
  end

  def as_audio_attributes
    {
      id: id.to_s,
      name: name,
      name_short: name_short,
      audios: audio_count,
      completed: (audio_count > 0) ? ((translated_audio_count*100)/audio_count).to_i : audio_count,
      status: self.status,
      reviewed: reviewed_audio_count,
      news: new_audio_count,
      translated: translated_audio_count,
      duration: duration && duration.gmtime.strftime('%H:%M:%S'),
      responsable: responsable,
      hasResponsable: !responsable.nil?,
      downloaded: downloaded?,
      created_at: created_at.strftime('%F')
    }
  end

  def prep_json( page= 1, options = {})
    audios = audio_files.paginate(page:page, per_page: 30)
    as_audio_attributes.merge({
      audio_files: audios.map{|a| a.prep_json(options) },
      pages: audios.total_pages,
    })
  end

  def to_json
    prep_json.to_json
  end

  def audio_count
    @audio_count ||= audio_files.count
  end

  def translated_audio_count
    @translated_audio_count ||= audio_files.only(:translation).where(:translation.ne => "").count
  end

  def reviewed_audio_count
    @reviewed_audio_count ||= audio_files.only(:status).where( status: "reviewed").count
  end

  def new_audio_count
    @new_audio_count ||= audio_files.only(:status).where( status: "new").count
  end

  private
    def name_short
      name.gsub(/^.*?vices\./, "").split(".").join("-")
    end

    def duration_miliseconds
      duration.to_i
    end

    def human_duration
      duration.gmtime.strftime('%R:%S')
    end

    def responsable
      return nil unless translator
      translator.min_json
    end
end
