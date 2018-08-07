class Integer

  def to_s
    return '%02d:%02d' % [(self / 60) % 24, self % 60]
  end

end

puts 10
