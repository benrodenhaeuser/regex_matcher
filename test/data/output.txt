09:        @matches = []
38:      def match?
42:      def match
46:      def match!
50:      def save_match
51:        @matches << match
59:      def found_match?
60:        !@matches.empty?
67:      def process_matches
68:        @matches.reverse.each do |match|
69:          process_match(match.first, match.last)
75:      def process_match(from, to)
77:        the_match = @text[from..to]
79:        @text     = pre + replace(the_match) + post
82:      def replace(the_match)
86:          the_match.colorize(:light_green).underline
90:          the_match
