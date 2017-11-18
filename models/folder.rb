class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  default_scope ->(){ order_by( id: 'asc') }

  scope :for_user, ->(user){ where(translator: user) }

  INFOLDER = "folders"
  OUTFOLDER = 'public/audio'
  OUTTXTFOLDER = 'public/output'

  field :name, type: String
  field :duration, type: Time
  field :status, type: String, default: 'imported'
  field :downloaded, type: Boolean, default: false

  belongs_to :translator, class_name: 'User'
  has_many :audio_files, dependent: :delete

  before_destroy do
    File.delete(zipfile_name) if File.exists?(zipfile_name)
    FileUtils.remove_dir(audio_wav_folder) if Dir.exists?(audio_wav_folder)
    FileUtils.remove_dir("#{audio_files_folder}") if Dir.exists?("#{audio_files_folder}")
  end

  include StateMachine
  include Importable
  include Accouting
  include Downloadable

  def take_by(user)
    self.translator = user
    save
    self
  end
end
