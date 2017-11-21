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

  def self.clear_empty_lines(name)
    name.gsub("\n", "").gsub(/^\s{1,}/m, "").gsub(/\s{1,}$/m, "")
  end
end
