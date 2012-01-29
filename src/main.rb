INITAT=Time.now

$LOAD_PATH << 'src'

ruby_lib_path = File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__)))), "ruby").to_s()[5..-1] 
if File.exists?( ruby_lib_path ) 
  LIB_PATH = File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))).to_s()[5..-1] 
else 
  LIB_PATH = 'lib' 
end

require "swt_wrapper"


require 'stringio'
require 'thread'
require "open-uri"
require "yaml"
require "open3"
%w{alert notification quit_window tray preference_panel report welcome_window}.each do | f |
  require "ui/#{f}"
end

require "app.rb"

if App::CONFIG['show_welcome']
  WelcomeWindow.new
end


Tray.instance.run

