require 'set'

class Set
  def singleton?
    size == 1
  end

  def unique_member
    raise 'Not a singleton!' if size != 1
    to_a.first
  end

  def nonempty?
    !empty?
  end

  def to_s
    '{' + to_a.map(&:to_s).join(', ') + '}'
  end
end
