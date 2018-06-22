module Refinements
  module FloatComma
    refine Float do
      def to_comma_string
        self.to_s.gsub('.', ',')
      end
    end
  end
end
