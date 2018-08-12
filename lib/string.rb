class String
  RED = 31
  UNDERLINE = 4

  def red
    "\e[#{RED}m#{self}\e[0m"
  end

  def underline
    "\e[#{UNDERLINE}m#{self}\e[0m"
  end

  def highlight(color)
    send(color).underline
  end
end
