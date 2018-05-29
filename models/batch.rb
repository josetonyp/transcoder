class Batch
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :audio_folders

  field :name, type: String
  field :folders_count, type: Integer

  def to_h
    {
      id: id.to_s,
      name: name,
      created_at: created_at.strftime('%F %T'),
      folders_count: folders_count,
      translated: translated,
      reviewed: reviewed
    }
  end

  def update_folders_count
    self.folders_count = audio_folders.count
    self.save!
  end

  def translated
    audio_folders.translated.count * 100 / audio_folders.count
  end

  def reviewed
    audio_folders.reviewed.count * 100 / audio_folders.count
  end
end
