module AudioFiles
  module StateMachine
    STATUS_LIST = ["created", "translated", "reviewed"]
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      STATUS_LIST.each do |attribute|
        define_method(attribute) do
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
      when "created"
        translated! unless translation.empty?
      when "translated"
        reviewed! unless translation.empty?
      end
    end

    def history
      status_changes.map(&:to_h)
    end
  end
end
