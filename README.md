# Chess AI

Chess AI, coded in Ruby, playable in terminal. The AI is powered by a negamax algorithm with alpha-beta pruning and a quiescent evaluation function.

## How To Play

### Setup

1. Clone this repo in your command line: `git clone https://github.com/AlexanderRichey/Chess`.
2. Navigate to the Chess directory.
3. Start a game by typing `ruby game.rb`.

### Game Play

- Choose a difficulty level at the game intro.
- Use the arrow keys to navigate the board.
- Press `Enter` to pick up and put down a piece. When a piece is selected, it will turn green.

### Saving and Loading Games

- Type `s` to save your game. You will be prompted to enter a filename and your file will be saved in the same directory in which your game is running.
- Load a game by typing `ruby game.rb your_game` in your command line.

## Technical Details

#### Background

The AI's moves are determined by a negamax algorithm and a board evaluation function. The negamax algorithm systematically makes every move available to the AI player; and the resulting board is given a score by the board evaluation function. The AI then makes the move that corresponds to the highest scoring board. (Open `players/computer_player.rb` to view my implementation.)

In order to look deeper into the game tree, that is, to look more than one move ahead, the negamax algorithm can be programed to make every possible move in response to its original move. In other words, the algorithm makes every move available to the AI player, and then, for each one of those moves, it makes every available response move on behalf of its opponent. The resulting board is then given a score by the same evaluation function. In this case, however, that score is negated. The reason for this is that the score, at this point in the game tree, will represent the board from the perspective of the AI's opponent. Since best score for the AI is identical to the worst score for the opponent and *vice versa*, the AI then chooses the move that corresponds to the highest scoring board, which, in this case, will be a negative number that represents the worst board for the AI's opponent. In pseudocode:
```
eval(board) for player A == -eval(board) for player B
```
Thus, the game tree can be evaluated to any given depth by negating the board score at each recurse.

#### The Challenge

Since, given infinite computational power, there exists a relatively strightforward way of finding all winning boards, the primary challenge in building a chess AI is not theoretical. The source of the challenge lies in the fact that our computational power is limited. Looking `n` moves ahead requires that `~35^n` boards be evaluated; that's 1.5 million boards to look only four moves ahead. What's more, it has been estimated that the total number of possible moves in chess is 10^120. To put this in perspective, the number of atoms in the universe is estimated to be 10^80. It would take a supercomputer more than billion years to evaluate all of these moves.

In order to deal with this level of complexity, I employed two canonical strategies to make my AI more effective: *alpha-beta pruning* and *quiescence*. Alpha-Beta pruning aims to reduce the number of game tree nodes that are explored by neglecting unpromising branches of the game tree, while quiescence aims to counteract the horizon effect.

#### Alpha-Beta Pruning

Alpha-Beta pruning reduces the number game tree nodes that are explored, which saves computational power. This is done by maintaining an upper and lower-bound board score, known as *alpha* and *beta* respectively. Alpha represents the minimum score that the current player is assured of. Beta represents the maximum score that her opponent is assured of. The key insight of alpa-beta pruning is that there are sometimes cases when alpha is greater than beta, that is, the minimum guaranteed score of the current player exceeds the maximum guaranteed score of her opponent. If such a case obtains, the negamax algorithm stops searching further and returns beta, since it is unlikely, given any subsequent moves down the branch, that the resulting score will be higher than alpha. Here is a concrete example of alpha-beta pruning in action:

> Say it is White's turn to move, and we are searching to a depth of two (that is, we are consider all of White's moves, and all of Black's responses to each of those moves.) First we pick one of White's possible moves - let's call this Possible Move #1. We consider this move and every possible response to this move by black. After this analysis, we determine that the result of making Possible Move #1 is an even position. Then, we move on and consider another of White's possible moves (Possible Move #2). When we consider the first possible counter-move by black, we discover that playing this results in black winning a Rook! In this situation, we can safely ignore all of Black's other possible responses to Possible Move #2 because we already know that Possible Move #1 is better. We really don't care exactly how much worse Possible Move #2 is. Maybe another possible response wins a Queen, but it doesn't matter because we know that we can achieve at least an even game by playing Possible Move #1. The full analysis of Possible Move #1 gave us a lower bound. We know that we can achieve at least that, so anything that is clearly worse can be ignored [Chess Programming Wiki](https://chessprogramming.wikispaces.com/Alpha-Beta).

Here's my implementation inside the negamax algorithm:
```ruby
...
if score >= beta
  return {
      score: beta,
      start_pos: start_pos,
      end_pos: end_pos
    }
end

if score > alpha
  alpha = score
  node = {
    score: alpha,
    start_pos: start_pos,
    end_pos: end_pos
  }
end

...

return node || alpha
```

#### Quiescence

Quiescent board evaluation functions work in tandem with an underlying evaluation function and aim to counteract the horizon effect.

> Consider the situation where the last move you consider is QxP. If you stop there and evaluate, you might think that you have won a pawn. But what if you were to search one move deeper and find that the next move is PxQ? You didn't win a pawn, you actually lost a queen. ([Chess Programming Wiki](https://chessprogramming.wikispaces.com/Quiescence+Search)).

In order to prevent situations like this one, a quiescent board evaluation function makes all available capture moves on behalf of the current player's opponent and then recursively calls itself until a score is yielded. After this, the function undoes the capture move and returns the resulting score. If there are no available capture moves, the function returns the score given by the underlying evaluation.

I also applied alpa-beta pruning to my `quiesce` function in order to prevent needless recursion. Here's the method:

```ruby
def quiesce(alpha, beta)
  stand_pat = self.evaluate # standard board evaluation

  if stand_pat >= beta
    return beta
  end

  if alpha < stand_pat
    alpha = stand_pat
  end

  board.capture_moves(color).each do |piece, moves|
    moves.each do |end_pos|
      start_pos = piece.pos
      start_piece = piece
      end_piece = board[end_pos]
      board.make_move!(start_pos, end_pos, start_piece)

      score = -quiesce(-beta, -alpha)

      board.undo_move!(start_pos, end_pos, start_piece, end_piece)

      if score >= beta
        return beta
      end

      if score > alpha
        alpha = score
      end

    end
  end

  return alpha
end
```

## Screenshot

![Screenshot](./images/screenshot.png)
