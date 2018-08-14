class String
  RED = 31
  DIM = 2
  UNDERLINE = 4
  ITALIC = 3

  def red
    "\e[#{RED}m#{self}\e[0m"
  end

  def italic
    "\e[#{ITALIC}m#{self}\e[0m"
  end

  def dim
    "\e[#{DIM}m#{self}\e[0m"
  end

  def underline
    "\e[#{UNDERLINE}m#{self}\e[0m"
  end

  def red_underline
    red.underline
  end

  def highlight(style)
    send(style)
  end
end
