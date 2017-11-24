class AudioFile
  include Mongoid::Document
  include Mongoid::Timestamps

  OUTFOLDER = 'public/output'

  belongs_to :audio_folder
  belongs_to :translator, class_name: 'User'
  belongs_to :reviewer, class_name: 'User'

  default_scope ->(){ order_by( id: 'asc') }

  scope :translated, -> { where(:status.ne => 'new')}
  scope :just_translated, -> { where(status: 'translated')}
  scope :reviewed, -> { where(status: 'reviewed')}

  field :name, type: String
  field :translation, type: String
  field :status, type: String, default: 'new'
  field :file, type: String
  field :duration, type: Float

  index({ id: 1 }, {  name: "id_index" })
  index({ name: 1, audio_folder: 1 }, { unique: true, name: "name_and_folder_uniq_index" })
  index({ audio_folder: 1 }, { name: "audio_folder_index" })
  index({ status: 1 }, { name: "status_index" })
  index({ audio_folder: 1, status: 1 }, { name: "audio_folder_status_index" })
  index({ translator: 1, status: 1 }, { name: "translator_status_index" })
  index({ audio_folder: 1, status: 1, id: 1 }, { name: "id_audio_folder_status_index" })

  def prep_json(options={})
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

  def file_name
    "#{OUTFOLDER}/#{audio_folder.id.to_s}/#{name}.txt"
  end

  def save_file
    File.delete(file_name) if File.exists?(file_name)
    File.write(file_name, translation)
  end

  def to_json
    prep_json.to_json
  end

  def self.upfind( name, folder )
    if where( name: name, audio_folder: folder ).exists?
      where( name: name, audio_folder: folder ).first
    else
      create!( name: name, audio_folder: folder )
    end
  end

  def waveme( outfile )
    wave = WaveInfo.new(outfile)
    update_attributes!( file: "/#{outfile}", duration: wave.duration, status: 'new', translation: '')
    print "."
    self
  end

  def txtme( text )
    update_attributes!( translation: text.strip, status: 'translated' )
    print "-"
    self
  end

  def reviewed_by!(user:)
    update_attributes!(status: 'reviewed', reviewer: user)
  end

  def translate(translation:, user:, review: false)
    if review
      reviewed_by!(user: user)
    else
      if translation.strip != "" && translation.strip != "[bad wave] ??"
        update_attributes!( translation: translation.strip, status: 'translated', translator: user )
      end
    end
    audio_folder.next! unless audio_folder.reviewed?
  end

  def self.total_duration
    sum(:duration)
  end

end
