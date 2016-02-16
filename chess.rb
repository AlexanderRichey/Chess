require_relative 'relatives'

class Game
  attr_reader :white, :black, :current_player

  def initialize(white, black)
    @white = :white
    @black = :black
    @current_player = :white
  end

  def switch_players!
    @current_player == white ? @current_player = black : @current_player = white
  end

  def play
    b = Board.new(self)
    b.populate_board
    d = Display.new(b)
    d.display_loop
  end
end

g = Game.new("Alex", "Dan")
g.play
