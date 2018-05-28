class AudioFile
  include Mongoid::Document
  include Mongoid::Timestamps

  OUTFOLDER = 'public/output'

  belongs_to :audio_folder
  belongs_to :translator, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true
  embeds_many :status_changes, class_name: '::Change'

  default_scope ->(){ order_by( id: 'asc') }

  field :name, type: String
  field :translation, type: String
  field :status, type: String, default: 'created'
  field :file, type: String
  field :duration, type: Float

  after_save do
    audio_folder.touch
  end

  index({ id: 1 }, {  name: "audio_id_index" })
  index({ name: 1, audio_folder: 1 }, { unique: true, name: "audio_name_and_folder_uniq_index" })
  index({ audio_folder: 1 }, { name: "audio_folder_index" })
  index({ status: 1 }, { name: "audio_status_index" })
  index({ audio_folder: 1, status: 1 }, { name: "audio_folder_status_index" })
  index({ translator: 1, status: 1 }, { name: "audio_translator_status_index" })
  index({ audio_folder: 1, status: 1, id: 1 }, { name: "audio_id_audio_folder_status_index" })

  def self.upfind( name, folder )
    if where( name: name, audio_folder: folder ).exists?
      where( name: name, audio_folder: folder ).first
    else
      create!( name: name, audio_folder: folder )
    end
  end

  def reviewed_by(user:)
    update_attributes!(reviewer: user)
    next! unless reviewed?
    audio_folder.next! unless audio_folder.reviewed?
  end

  def translated_by(translation:, user:)
    if translation.strip != "" && translation.strip != "[bad wave] ??"
      update_attributes!( translation: translation.strip, translator: user )
    end
    next! unless translated?
    # Move forward the folder in case all audios are translated
    audio_folder.next! unless audio_folder.reviewed?
  end

  def self.total_duration
    sum(:duration)
  end

  include AudioFiles::StateMachine
  include AudioFiles::Importable
  include AudioFiles::Serialisable
end
