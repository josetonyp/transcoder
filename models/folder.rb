class AudioFolder
  include Mongoid::Document
  include Mongoid::Timestamps

  scope :by_index, ->(){ order_by( id: 'asc') }
  scope :by_last_updated, ->(){ order_by( updated_at: 'desc') }

  scope :for_user, ->(user){ where(translator: user) }

  INFOLDER = "folders"
  OUTFOLDER = 'public/audio'
  OUTTXTFOLDER = 'public/output'

  field :name, type: String
  field :duration, type: Time
  field :status, type: String, default: 'imported'
  field :downloaded, type: Boolean, default: false

  belongs_to :translator, class_name: 'User', optional: true
  has_many :audio_files, dependent: :destroy # it could be embed
  embeds_many :status_changes, class_name: '::Change'

  belongs_to :batch, optional: true
  belongs_to :invoice, optional: true

  index({ id: 1 }, {  name: "id_index" })
  index({ name: 1 }, { unique: true, name: "name_index" })
  index({ batch: 1 }, { unique: true, name: "batch_index" })
  index({ invoice: 1 }, { unique: true, name: "invoice_index" })
  index({ status: 1 }, { name: "status_index" })
  index({ translator: 1, status: 1 }, { name: "translator_status_index" })
  index({ translator: 1, status: 1, updated_at: 1 }, { name: "translator_status_updated_index" })

  before_destroy do
    audio_files.destroy_all
    remove_audio_files
  end

  include StateMachine
  include Importable
  include Accouting
  include Downloadable
  include Serialisable

  def take_by(user)
    self.translator = user
    save
    self
  end

  def touch
    self.updated_at = Time.now.utc
    self.save
  end

  private

  def remove_audio_files
    File.delete(zipfile_name) if File.exists?(zipfile_name)
    FileUtils.remove_dir(audio_wav_folder) if Dir.exists?(audio_wav_folder)
    FileUtils.remove_dir("#{audio_files_folder}") if Dir.exists?("#{audio_files_folder}")
  end
end
