class Batch
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :audio_folders

  field :name, type: String


  def to_h
    {
      id: id.to_s,
      name: name,
      created_at: created_at.strftime('%F %T')
    }
  end
end
