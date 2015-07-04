class AudioFile
  include Mongoid::Document
  include Mongoid::Timestamps

  OUTFOLDER = 'public/output'

  belongs_to :audio_folder
  belongs_to :translator, class_name: 'User'
  belongs_to :reviewer, class_name: 'User'

  default_scope ->(){ order_by( id: 'asc') }

  field :name, type: String
  field :translation, type: String
  field :status, type: String, default: 'new'
  field :file, type: String
  field :duration, type: Float

  index({ id: 1 }, {  name: "id_index" })
  index({ name: 1 }, { unique: true, name: "name_index" })
  index({ audio_folder: 1 }, { name: "audio_folder_index" })
  index({ status: 1 }, { name: "status_index" })
  index({ audio_folder: 1, status: 1 }, { name: "audio_folder_status_index" })
  index({ audio_folder: 1, status: 1, id: 1 }, { name: "id_audio_folder_status_index" })

  def prep_json(options={})
    {
      id: id.to_s,
      name: name,
      translation: translation,
      status: status,
      translator: translator,
      public_file: file.gsub('/public', ''),
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
    update_attributes!( file: "/#{outfile}", duration: wave.duration )
    self
  end

  def txtme( text )
    update_attributes!( translation: text )
    self
  end

  def translate(params, user)
    update_attributes!( translation: params["value"].strip, status: "translated", translator: user ) if params["value"] != "" && params["value"] != "[bad wave] ??"
  end

end
