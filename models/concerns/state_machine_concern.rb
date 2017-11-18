module StateMachine
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    ["imported", "started", "translated", "reviewed", "downloaded"].each do |attribute|
      define_method("#{attribute}") do
        where(status: attribute.to_s)
      end
    end
  end
  # [imported, started, ready, translated, reviewed, downloaded] hacer funciones para los estados

  ["imported", "started", "translated", "reviewed", "downloaded"].each do |attribute|
    define_method("#{attribute}!") do
      self.update_attributes(status: attribute.to_s)
    end

    define_method("#{attribute}?") do
      self.status == attribute.to_s
    end
  end
end
