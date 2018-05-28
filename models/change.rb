class Change
  include Mongoid::Document
  include Mongoid::Timestamps

  field :from, type: String
  field :to, type: String

  embedded_in :audio_folder
  embedded_in :audio_file

  def to_h
    {
      from: self.from,
      to: self.to,
      created_at: created_at.strftime('%F %T')
    }
  end
end
