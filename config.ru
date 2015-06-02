require "./rack_interface"
use Rack::Static, :urls => ["/stylesheets"], :root => "public"
use Rack::Reloader
run RackInterface