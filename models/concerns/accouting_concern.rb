module Accouting
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def total_duration
      all.map{|f| f.duration.to_i }.inject(:+)
    end

    def human_total_duration
      Time.at(total_duration).gmtime.strftime('%R:%S')
    end

    def payroll_total
      (Time.at(total_duration).gmtime.strftime('%H').to_f * 58) +
      (Time.at(total_duration).gmtime.strftime('%M').to_f * (58 / 60.0) )
    end

    def ganancia
      payroll_total - User.all.map(&:payroll).inject(:+)
    end

    def by_user
      User.all.map{|u| [ u.name, u.audio_folders.map(&:duration_miliseconds).inject(:+)] }
    end
  end
end
