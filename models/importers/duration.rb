require 'csv'
module Importers
  class Duration
    def self.parse(file)
      CSV.foreach(file) do |name, duration, count|
        if name
          name = name.to_s.gsub(".zip", "")
          duration = (duration.strip.to_f * 100).to_i
          ap "importing #{name} with: #{duration}"
          # import(name, duration)
          ap "-"*60
        end
      end
    end

    def self.import(name, duration)
      AudioFolder.where(name: name).first.update_attributes(percent_duration: duration)
    end
  end
end
