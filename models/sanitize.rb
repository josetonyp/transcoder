module Sanitize
  def self.base(name)
    name.gsub(/\s{2,}/, " ").gsub(/\s/, "_").match(/[^\/]*?$/).to_s
  end
  def self.zip( name )
    base(name.gsub(".zip", ""))
  end
  def self.txt( name )
    base(name.gsub(".txt", ""))
  end
end
