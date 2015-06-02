require 'bundler/setup'
require "erb"
require "codebreaker"
 
class RackInterface
  def self.call(env)
    new(env).response.finish
  end
   
  def initialize(env)
    @request = Rack::Request.new(env)
    @game    = Codebreaker::Game.new

    @user_name = @request.params["user_name"]
    @attempts  = @request.params["attempts"]
    @user_id   = @request.cookies["user_id"]
    @user_code = @request.params["user_code"]
    #@user_info = YAML.load(File.open("./data/#{@user_id}.txt"))
    @results   = YAML.load(File.open("./data/save_result.txt"))
  end
   
  def response
    case @request.path
    when "/" 
      if @user_id  
        @user_info = @game.get_user_info(@user_id)
        Rack::Response.new { |response| response.redirect("/game") }
      else 
        @user_info = nil
        Rack::Response.new(render("index.html.erb"))
      end
    when "/start_game"
      unless @user_id
        Rack::Response.new do |response|
          response.set_cookie("user_id", @game.user_id)
          @game.save_new_values(@user_name, @attempts)
          response.redirect("/game")
        end
      else
        @game.user_id = @user_id
        @game.save_new_values(@user_name, @attempts)
        Rack::Response.new { |response| response.redirect("/game") }
      end
    when "/game"       
      if @user_id
        @user_info = @game.get_user_info(@user_id)
        Rack::Response.new(render("game.html.erb"))
      else 
        Rack::Response.new { |response| response.redirect("/") }
      end
    when "/action"
      unless @game.comparison_codes(@user_id, @user_code)
        @game.user_code = @user_code
        result = @game.create_answer(@user_id)
        @game.update_value(@user_id, @user_code, result)
      end
      Rack::Response.new { |response| response.redirect("/game") }
    when "/hint"
      @game.hint_code = @game.requests_hint(@user_id)
      Rack::Response.new { |response| response.redirect("/game") }
    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

end