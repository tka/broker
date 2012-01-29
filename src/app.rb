require "compile_version.rb"

module App
  extend self

  include CompileVersion
  VERSION = "0.1"
  OS = org.jruby.platform.Platform::OS 
  OS_VERSION = java.lang.System.getProperty("os.version")

  def version
    VERSION
  end

  def compile_version
    "#{OS}.#{OS_VERSION}.#{org.jruby.platform.Platform::ARCH}.#{COMPILE_TIME}.#{REVISION}"
  end

  
  CONFIG_DIR = File.join( java.lang.System.getProperty("user.home") , '.broker' )

  Dir.mkdir( CONFIG_DIR ) unless File.exists?( CONFIG_DIR )

  HISTORY_FILE =  File.join( CONFIG_DIR, 'history')
  CONFIG_FILE  =  File.join( CONFIG_DIR, 'config')

  def get_system_default_gem_path
    begin
      %x{gem env gempath}.strip.split(/:/).first
    rescue => e
      nil
    end
  end

  def get_config
    begin 
      x = YAML.load_file( CONFIG_FILE ) 
    rescue => e
      x = {} 
    end

                                
    config = {
      "middleman_command" => { 
      "init" => "middleman init",
      "build" => "middleman build",
      "server" => "middleman server",
    },
    "show_welcome" => true
    }.merge!(x)

  end
 
  CONFIG = get_config

  def save_config
    open(CONFIG_FILE,'w') do |f|
      f.write YAML.dump(CONFIG)
    end

  end

  def clear_histoy
    set_histoy([])
  end

  def set_histoy(dirs)
    File.open(HISTORY_FILE, 'w') do |out|
      YAML.dump(dirs, out)
    end 
  end 

  def get_history
    dirs = YAML.load_file( HISTORY_FILE ) if File.exists?(HISTORY_FILE)
    return dirs if dirs
    return []
  end 

  def display
    Swt::Widgets::Display.get_current
  end

  def create_shell(style = nil)
    style ||= Swt::SWT::NO_FOCUS | Swt::SWT::NO_TRIM
    Swt::Widgets::Shell.new( Swt::Widgets::Display.get_current, style)
  end

  def create_image(path)
    Swt::Graphics::Image.new( Swt::Widgets::Display.get_current, java.io.FileInputStream.new( File.join(LIB_PATH, 'images', path)))
  end

  def get_stdout
    begin
      sio = StringIO.new
      old_stdout, $stdout = $stdout, sio 
      #  Invoke method to test that writes to stdout
      yield
      output = sio.string.gsub(/\e\[\d+m/,'')
    rescue Exception => e  	
      output = e.message
    end
    $stdout = old_stdout # restore stdout
    return output
  end

  def notify(msg, target_display = nil )
    if org.jruby.platform.Platform::IS_MAC
      system('/usr/bin/osascript', "#{LIB_PATH}/applescript/growl.scpt", msg )
    else
      Notification.new(msg, target_display)
    end
  end

  def report(msg, target_display = nil)
    Report.new(msg, target_display)
  end
  
  def alert(msg, target_display = nil)
    Alert.new(msg, target_display)
  end

  def try
    begin
      yield
    rescue Exception => e
      report("#{e.message}\n#{e.backtrace.join("\n")}")
    end
  end

  def scan_library( dir )
    Dir.new( dir ).entries.reject{|e| e =~ /^\./}.each do | subfolder|
      lib_path = File.join(dir, subfolder,'lib')
      $LOAD_PATH.unshift( File.join( dir, subfolder, 'lib') ) if File.exists?(lib_path)
    end

  end
  
end

