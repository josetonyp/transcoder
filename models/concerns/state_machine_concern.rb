module StateMachine
  STATUS_LIST =  ["imported", "started", "translated", "reviewed", "downloaded", "delivered",  "invoiced", "paid", "archived"]

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    STATUS_LIST.each do |attribute|
      define_method("#{attribute}") do
        where(status: attribute.to_s)
      end
    end
  end

  STATUS_LIST.each do |attribute|
    define_method("#{attribute}!") do
      self.status_changes.create!(from: self.status, to: attribute.to_s)
      self.update_attributes(status: attribute.to_s)
    end

    define_method("#{attribute}?") do
      self.status == attribute.to_s
    end
  end

  def next!
    case status
    when "imported"
      started! if audio_files.translated.count > 0
    when "started"
      translated! if audio_files.created.count ==  0
    when "translated"
      reviewed! if audio_files.translated.count  ==  0
    when "reviewed"
      downloaded! if audio_files.translated.count  ==  0
    when "downloaded"
      delivered! if audio_files.where(reviewer: nil).count  ==  0
    when "delivered"
      invoiced!
    when "invoiced"
      paid!
    when "paid"
      remove_audio_files
      archived!
    end
    touch
    self
  end

  def history
    status_changes.map(&:to_h)
  end
end
