require 'set'

class Set
  def singleton?
    size == 1
  end

  def elem
    raise 'Not a singleton!' unless singleton?
    to_a.first
  end

  def to_s
    '{' + to_a.map(&:to_s).join(', ') + '}'
  end
end
