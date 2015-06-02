require 'bundler/setup'
require "erb"
require "codebreaker"
 
class Racker
  def self.call(env)
    new(env).response.finish
  end
   
  def initialize(env)
    @request = Rack::Request.new(env)
    @game = Codebreaker::Game.new
  end
   
  def response
    case @request.path
    when "/" 
      if @request.cookies["user_id"] 
        @user_info = @game.get_user_info(@request.cookies["user_id"])
      else 
        @user_info = nil
      end
      Rack::Response.new(render("index.html.erb"))
    when "/start_game"
      unless @request.cookies["user_id"]
        Rack::Response.new do |response|
          response.set_cookie("user_id", @game.user_id)
        end
      else
        @game.user_id = @request.cookies["user_id"]
      end
      @game.save_new_values(@request.params["user_name"], @request.params["attempts"])
      response.redirect("/game")
    when "/game"       
      if @request.cookies["user_id"]
        @user_info = @game.get_user_info(@request.cookies["user_id"])
        Rack::Response.new(render("game.html.erb"))
      else 
        response.redirect("/")
      end
    when "/action"
      @game.load_value(@request.cookies["user_id"])
      result = @game.comparison_codes(@request.params["user_code"])
      @game.update_value(@request.params["user_code"], result)
      @game.save_value()
      response.redirect("/game")
    when "/hint"
      @game.load_value(@request.cookies["user_id"])
      @game.hint_code = @game.requests_hint
      @game.save_value()
      response.redirect("/game")
    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

end