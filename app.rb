require 'sinatra'

enable :sessions

@@wordlist = File.open("./public/5desk.txt").readlines

get '/' do
  p session	

  if session[:game_over] || session[:answer].nil?
  	redirect to '/new'
  end

  erb :index
end

get '/new' do
  set_vars
  redirect to '/'
end

get '/lose' do
  unless session[:game_over]
  	redirect to '/'
  end
  erb :lose
end

get '/win' do
  unless session[:game_over]
  	redirect to '/'
  end
  erb :win
end

post '/' do
  guess = params['guess'].downcase
  p guess
  begin 
  	check_if_valid(guess)
  rescue NoResponse
  	session[:error_message] = "Please enter a letter!"
  rescue TooManyLetters
  	session[:error_message] = "Too many letters!"
  rescue AlreadyGuessed
	session[:error_message] = "You already guessed that letter!"
  rescue NotALetter
  	session[:error_message] = "Your guess is not a letter!"
  else
  	check_guess(guess)
  ensure
  	p session[:error_message]
  	redirect to '/'
  end
end

helpers do
  def set_vars
    session[:remaining_guesses] = 7
	session[:guessed_letters] = Array.new
	#session[:answer] = select_word
	session[:answer] = "abcd" # For debugging 
 	session[:pattern] = initialize_pattern
	session[:game_over] = false
	session[:error_message] = ""
  end

  def select_word
    @choices = @@wordlist.select { |word| word.length.between?(7, 10) }
    @selected_word = @choices.sample.downcase
  end

  def initialize_pattern
	@pattern = "_"	
	(session[:answer].length - 1).times do
	  @pattern += " _"
	end
	@pattern
  end

  def check_if_valid letter
  	p "Entered check_if_valid"
	raise NoResponse if letter.to_s.empty? 
	raise TooManyLetters if letter.length > 1 
	raise AlreadyGuessed if session[:guessed_letters].include?(letter) 
	raise NotALetter unless letter =~ /[[:alpha]]/ 
  end

  def check_guess letter
  	p "Entered check_guess"
  	if session[:answer].include?(letter) && !session[:guessed_letters].include?(letter)
  	  session[:guessed_letters] << letter
  	  session[:pattern] = update_pattern(letter)
  	else
      session[:remaining_guesses] -= 1

  	end
  end

  def update_pattern letter
  	pattern_array = session[:pattern].split(" ")
  	session[:answer].each_char.with_index do |char, index|
  	  if char == letter
  	  	pattern_array[index] = letter
  	  end
  	end
  	session[:pattern] = pattern_array.join(" ").strip
  end

  def won?

  end

  def lost?
    session[:remaining_guesses] == 0
  end
end
