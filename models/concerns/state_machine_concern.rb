module StateMachine
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    ["imported", "started", "translated", "reviewed", "downloaded", "delivered", "paid"].each do |attribute|
      define_method("#{attribute}") do
        where(status: attribute.to_s)
      end
    end
  end
  # [imported, started, ready, translated, reviewed, downloaded], "delivered", "paid" hacer funciones para los estados

  ["imported", "started", "translated", "reviewed", "downloaded", "delivered", "paid"].each do |attribute|
    define_method("#{attribute}!") do
      self.update_attributes(status: attribute.to_s)
    end

    define_method("#{attribute}?") do
      self.status == attribute.to_s
    end
  end

  def next!
    case status
    when "imported"
      started! if translated_audio_count > 0
    when "started"
      translated! if translated_audio_count ==  audio_count
    when "translated"
      reviewed! if reviewed_audio_count  ==  audio_count
    end
  end
end
