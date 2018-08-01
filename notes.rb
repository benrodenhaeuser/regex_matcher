def match!
  # we need to define cursor as @line[@position] somewhere

  (0..@line.length).each do |start_index|

    @state = initial
    @position = start_index
    @from = @position

    loop do

      if terminal.include?(@state)
        @to = @position
      end

      if state.moves[cursor]
        state = state.moves[cursor]
        @position += 1
      end
    end

    break if match?
  end
end
