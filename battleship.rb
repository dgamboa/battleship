SHIP_HASH = Hash["submarine", 1, "destroyer", 2, "cruiser", 3, "battleship", 4, "aircraft carrier", 5]

class Game
  def initialize
    @user = Player.new("Human")
    @computer = Player.new("Computer")
    @current_player, @other_player = @user, @computer

    while true
      human_turn
      sleep(1.5)
      turn_order
      computer_turn
      sleep(3)
      turn_order
    end
  end

  def turn_order
    if @current_player == @user
      @current_player, @other_player = @computer, @user
    else
      @current_player, @other_player = @user, @computer
    end
  end

  # human attack
  def human_turn
    human_turn_message
    human_attack
  end

  def human_turn_message
    puts "It's your turn to attack! You have #{@current_player.fleet.fleet.length} ships afloat,
    so you have #{@current_player.fleet.fleet.length} shots."
    puts "Here's the enemy's board:"
    @other_player.player_board.enemy_board
  end

  def human_attack
    @current_player.fleet.fleet.length.times do
      sleep(0.5)
      2.times do
        print "."
        sleep(0.25)
      end
      puts "."
      puts
      puts
      puts
      puts "Enter your attack coordinate. For example, to attack the top left square
      type A1."
      @attack_coordinate = gets.chomp

      until valid_coordinate?
        puts "Invalid entry. Make sure your shot lands on the board."
        sleep(1.5)
        puts "Enter your attack coordinate:"
        @attack_coordinate = gets.chomp
      end

      parse_attack
      @other_player.player_board.enemy_board
    end

  end

  # computer attack
  def computer_turn
    computer_turn_message
    computer_attack
  end

  def computer_turn_message
    puts "The computer is beginning its attacks! It has #{@current_player.fleet.fleet.length} shots!"
    sleep(3)
  end

  def computer_attack
    @current_player.fleet.fleet.length.times do |i|
      sleep(2)
      print "Computer attacking"
      2.times do
        print "."
        sleep (0.25)
      end
      puts "."
      puts
      puts
      puts
      puts "Computer attack #{i + 1}:"
      @computer_attack_coordinate = [rand(10) + 1, rand(10) + 1]
      @computer_attack_coordinate_contents = @other_player.player_board.board[@computer_attack_coordinate[0]][@computer_attack_coordinate[1]]

      until @computer_attack_coordinate_contents != "/" || "X"
        @computer_attack_coordinate = [rand(10) + 1, rand(10) + 1]
        @computer_attack_coordinate_contents = @other_player.player_board.board[@computer_attack_coordinate[0]][@computer_attack_coordinate[1]]
      end

      attack_result(@computer_attack_coordinate[1], @computer_attack_coordinate[0])
    end
  end

  # shared attack methods
  def valid_coordinate?
    /[A-J]([1-9]|10)/.match(@attack_coordinate) ? true : false
  end

  def parse_attack
    column_hash = Hash[("A".."J").to_a.zip((1..10).to_a)]
    column_value = column_hash[@attack_coordinate.slice!(0)]
    row_value = @attack_coordinate.to_i
    attack_result(column_value, row_value)
  end

  def attack_result(column_value, row_value)

    case @other_player.player_board.board[row_value][column_value]
    when " "
      @other_player.player_board.board[row_value][column_value] = "/"
      puts "Miss!"
      if @current_player == @computer
        puts "Here's the status of your fleet:"
        @other_player.player_board.printed_board
      end
    when "s", "a", "b", "c", "d"
      puts "Hit!"
      @other_player.fleet.damage_taken(@other_player.player_board.board[row_value][column_value])
      @other_player.player_board.board[row_value][column_value] = "X"
      if @current_player == @computer
        puts "Here's the status of your fleet:"
        @other_player.player_board.printed_board
      end
      end_game if game_over?
    else
      if @current_player == @computer
        puts "Wasted shot! You already fired on that square, idiot!"
      end
      sleep(1)
    end
  end

  def game_over?
    @other_player.fleet.fleet.empty?
  end

  def end_game
    if @current_player.player_type == "Human"
      puts "-" * 68
      puts "Computer: I know now why you cry. But it is something I can never do."
      puts "-" * 68
      puts "Human wins!"
      puts
      puts
      puts
      puts "Thanks for playing!"
      exit
    else
      puts "-" * 68
      puts "Computer: Inferior human! Victory is mine!"
      puts "-" * 68
      puts "Computer wins!"
      puts
      puts
      puts
      puts "Thanks for playing!"
      exit
    end

  end

end

class Player
  attr_accessor :fleet, :player_type, :player_board

  def initialize(player_type)
    @player_type = player_type
    @fleet = Fleet.new()

    if @player_type == "Human"
      @player_board = Board.new
      initial_message
      ship_placement_message
    else
      @player_board = Board.new
      computer_ship_placement
    end
  end

  def ship_sunk
    @fleet -= 1
  end

  # human methods
  def initial_message
    puts "Welcome to Battleship!
    In a minute, you'll place your ships on the board. this program
    takes input coordinates in the form of LetterNumber, which
    corresponds to ColumnRow, for instance, the top left square is
    A1, the bottom right is J10. In this version of battleship, you
    fire a salvo each turn, where a salvo is a series of shots equal
    to the number of remaining ships on your board."
    sleep(5)
    puts "-" * 68
    puts "Here's the blank board:"
    @player_board.printed_board
  end

  def ship_placement_message
    puts "It's time to place your ships on the board! You have five
    ships of differing length:"
    SHIP_HASH.each do |name, length|
      puts "ship: #{name.ljust(18)}| length: #{length}"
    end
    puts "To place a ship, enter the ship's top-leftmost coordinate
    followed by a V to orient the ship vertically, or an H to orient
    the ship horizontally. For example, to place your aircraft carrier
    from A1 to A5, type A1V."
    sleep(5)
    ship_placement
  end

  def ship_placement
    SHIP_HASH.each do |ship, length|
      puts "Place your #{ship}, which is #{length} spaces long."
      @placement = gets.chomp

      until valid_coordinate?
        puts "Invalid entry. Make sure your piece fits on the board."
        sleep(1.5)
        puts "Place your #{ship}, which is #{length} spaces long."
        @placement = gets.chomp
      end

      placement_coordinates(ship)
      until available?
        puts "Invalid entry. Make sure your piece isn't overlapping with another ship."
        sleep(1.5)
        @player_board.printed_board
        puts "Place your #{ship}, which is #{length} spaces long."
        @placement = gets.chomp
        placement_coordinates(ship)
      end

      @player_board.add_ship_to_board(@placement_coordinate_array, ship)
      @player_board.printed_board
    end
  end

  # computer methods
  def computer_ship_placement
    random_row = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    random_orientation = ["H", "V"]
    SHIP_HASH.each do |ship, length|
      @placement = "#{random_row[rand(10)]}#{rand(10) + 1}#{random_orientation[rand(2)]}"
      placement_coordinates(ship)
      until existing_square? && available?
        @placement = "#{random_row[rand(10)]}#{rand(10) + 1}#{random_orientation[rand(2)]}"
        placement_coordinates(ship)
      end

      @player_board.add_ship_to_board(@placement_coordinate_array, ship)
    end
  end

  # coordinates
  def placement_coordinates(ship)
    column_value, row_value, orientation = parse_placement
    @placement_coordinate_array = []

    i = 0
    if orientation == "V"
      SHIP_HASH[ship].times do
        @placement_coordinate_array << [row_value + i, column_value]
        i += 1
      end
    elsif orientation == "H"
      SHIP_HASH[ship].times do
        @placement_coordinate_array << [row_value, column_value + i]
        i += 1
      end
    end

    @placement_coordinate_array
  end

  def valid_coordinate?
    /[A-J]([1-9]|10)[V,H]/.match(@placement) ? true : false
  end

  def parse_placement
    column_hash = Hash[("A".."J").to_a.zip((1..10).to_a)]
    column_value = column_hash[@placement.slice!(0)]
    orientation = @placement.slice!(-1)
    row_value = @placement.to_i
    return column_value, row_value, orientation
  end

  def available?
    var = true
    @placement_coordinate_array.each do |coordinate|
       if @player_board.board[coordinate[0]][coordinate[1]] != " "
         var = false
       end
     end
    var
  end

  def existing_square?
    var = true
    @placement_coordinate_array.each do |coordinate|
      if coordinate[0] > 10 || coordinate[1] > 10
        var = false
      end
    end
    var
  end

end

class Board

  attr_accessor :board

  def initialize
    @board = board_layout
  end

  def board_layout
    board_layout = Array.new(10, " ").map!{|row| Array.new(10, " ")}
    row_label = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    column_label = ["  ", "1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7 ", "8 ",  "9 ", "10"]
    board_layout.unshift(row_label)
    board_layout.each_with_index do |row, i|
      row.unshift(column_label[i])
    end
  end

  def printed_board(board_to_print = @board)
    puts "-" * 68; board_to_print.each { |row| print "|  "; print row.join("  |  "); puts "  |"; puts "-" * 68 }
  end

  def add_ship_to_board(placement_coordinate_array, ship)
    placement_coordinate_array.each do |coordinate|
      @board[coordinate[0]][coordinate[1]] = ship[0]
    end
  end

  def enemy_board
    ship_letters = ["s", "d", "c", "b", "a"]
    displayed_enemy_board = @board.map do |row|
      row.map do |square|
        ship_letters.include?(square) ? square = " " : square
      end
    end

    printed_board(displayed_enemy_board)
  end

  def square_contents(coordinate)
    @board[coordinate[0]][coordinate[1]]
  end

end

class Fleet
  attr_accessor :fleet

  def initialize
    @fleet = Hash["submarine", 1, "destroyer", 2, "cruiser", 3, "battleship", 4, "aircraft carrier", 5]
  end

  def is_sunk?(ship) # called on your own fleet when you're being fired upon
    if @fleet[ship] == 0
      @fleet.delete(ship)
    end
  end

  def damage_taken(ship_type)
    @fleet.each do |ship, health|
      if ship_type == ship[0]
        @fleet[ship] = health - 1
        is_sunk?(ship) ?  (puts "A ship has been sunk!") : (puts "A ship has been hit!")
      end
    end
  end

end

Game.new