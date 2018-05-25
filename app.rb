require 'sinatra'
require 'sinatra/reloader' if development?

enable :sessions

@@wordlist = File.open("./public/5desk.txt").readlines

get '/' do
  p "====== get /"
  p "#{session[:answer]}"
  redirect to '/new' if session[:game_over] || session[:answer].nil?
  redirect to '/win' if won?
  redirect to '/lose' if lost?
  erb :index
end

get '/new' do
  p "====== get /new"
  set_vars
  redirect to '/'
end

get '/lose' do
  p "====== get /lose"
  session[:game_over] = true
  erb :lose
end

get '/win' do
  p "====== get /win"
  session[:game_over] = true
  erb :win
end

post '/try' do
  p "====== post /try"
  guess = params['guess'].downcase
  p guess
  begin 
  	check_no_response(guess)
  	check_too_many_letters(guess)
  	check_already_guessed(guess)
  	check_not_a_letter(guess)
  rescue NoResponse
  	session[:error_message] = "Please enter a letter!"
  rescue TooManyLetters
  	session[:error_message] = "Too many letters!"
  rescue AlreadyGuessed
	session[:error_message] = "You already guessed that letter!"
  rescue NotALetter
  	session[:error_message] = "Your guess is not a letter!"
  else
  	p "No errors!"
  	check_guess(guess)
  ensure
  	p session[:error_message]
  	redirect to '/'
  end
end

configure do
  set :public_folder, File.expand_path('../public', __FILE__)
  set :views        , File.expand_path('../views', __FILE__)
  set :root         , File.dirname(__FILE__)
end


helpers do
  def set_vars
   p ">>>>>> set_vars" 	
    session[:remaining_guesses] = 3
	session[:guessed_letters] = Array.new
	#session[:answer] = select_word
	session[:answer] = "abcd" # For debugging 
 	session[:pattern] = initialize_pattern
	session[:error_message] = ""
	session[:game_over] = false
  end

  def select_word
  	p ">>>>>> select_word" 	
    @choices = @@wordlist.select { |word| word.length.between?(7, 10) }
    @selected_word = @choices.sample.downcase.strip
  end

  def initialize_pattern
	@pattern = "_"	
	(session[:answer].length - 1).times do
	  @pattern += " _"
	end
	@pattern
  end

  def check_no_response letter
	raise NoResponse if letter.to_s.empty? 
  end

  def check_too_many_letters letter
	raise TooManyLetters if letter.length > 1 
  end

  def check_already_guessed letter
	raise AlreadyGuessed if session[:guessed_letters].include?(letter) 
  end
  	
  def check_not_a_letter letter
	raise NotALetter unless letter =~ /[A-Za-z]/
  end

  def check_guess letter
  	p "Entered check_guess"
  	if session[:answer].include?(letter) && !session[:guessed_letters].include?(letter)
  	  session[:pattern] = update_pattern(letter)
  	else
      session[:remaining_guesses] -= 1
  	end
      session[:guessed_letters] << letter
  end

  def update_pattern letter
  	pattern_array = session[:pattern].split(" ")
  	session[:answer].each_char.with_index do |char, index|
  	  if char == letter
  	  	pattern_array[index] = letter
  	  end
  	end
  	session[:pattern] = pattern_array.join(" ").strip
  	p "#{session[:pattern_array]}"
  	session[:pattern]
  end

  def won?
  	p ">>>>>> won?" 	
  	p "#{session[:pattern]}"
  	!session[:pattern].split(" ").include?("_")
  end

  def lost?
  	p ">>>>>> lost?" 	
  	p "#{session[:remaining_guesses]}"
    session[:remaining_guesses] == 0
  end
end
