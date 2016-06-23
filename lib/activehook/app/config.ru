require 'activehook'
require 'activehook/app/base'
require 'byebug'

use ActiveHook::App::Middleware
run -> (env) { [200, {"Content-Type" => "text/html"}, ["Hello World!"]] }
