# Taken from http://stackoverflow.com/questions/6449373/wildcard-string-matching-in-ruby

class Globber
  def self.parse_to_regex(str)
    escaped = Regexp.escape(str).gsub('\*','.*?')
    Regexp.new "^#{escaped}$", Regexp::IGNORECASE
  end

  def initialize(str)
    @regex = self.class.parse_to_regex str
  end

  def =~(str)
    !!(str =~ @regex)
  end
end
