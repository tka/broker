require "singleton"
class Tray
  include Singleton

  def initialize()
    @watch_pipe    = nil
    @watching_dir  = nil
    @history_dirs  = App.get_history
    @shell    = App.create_shell(Swt::SWT::ON_TOP | Swt::SWT::MODELESS)

    @standby_icon = App.create_image("icon/16_dark.png")
    @watching_icon = App.create_image("icon/16.png")

    @tray_item = Swt::Widgets::TrayItem.new( App.display.system_tray, Swt::SWT::NONE)
    @tray_item.image = @standby_icon
    @tray_item.tool_tip_text = "broker"
    @tray_item.addListener(Swt::SWT::Selection,  update_menu_position_handler) unless org.jruby.platform.Platform::IS_MAC
    @tray_item.addListener(Swt::SWT::MenuDetect, update_menu_position_handler)

    @menu = Swt::Widgets::Menu.new(@shell, Swt::SWT::POP_UP)

    @watch_item = add_menu_item( "Watch a Folder...", open_dir_handler)

    add_menu_separator

    @history_item = add_menu_item( "History:")

    build_history_menuitem

    add_menu_separator

    item =  add_menu_item( "Create Middleman Project", empty_handler, Swt::SWT::CASCADE)
    item.menu = Swt::Widgets::Menu.new( @menu )
    add_menu_item( 'Default', create_project_handler,   Swt::SWT::PUSH, item.menu)
    add_menu_item( 'HTML5',   create_project_handler,   Swt::SWT::PUSH, item.menu)
    add_menu_item( 'Mobile',  create_project_handler,   Swt::SWT::PUSH, item.menu)

    item =  add_menu_item( "Preference...", preference_handler, Swt::SWT::PUSH)

    item =  add_menu_item( "About", open_about_link_handler, Swt::SWT::CASCADE)
    item.menu = Swt::Widgets::Menu.new( @menu )
    add_menu_item( 'Homepage',                      open_about_link_handler,   Swt::SWT::PUSH, item.menu)
    add_menu_separator( item.menu )

    add_menu_item( "App Version: #{App.version}",                          nil, Swt::SWT::PUSH, item.menu)
    add_menu_item( App.compile_version, nil, Swt::SWT::PUSH, item.menu)

    add_menu_item( "Quit",      exit_handler)
  end

  def run
    puts 'tray OK, spend '+(Time.now.to_f - INITAT.to_f).to_s
    while(!@shell.is_disposed) do
      App.display.sleep if(!App.display.read_and_dispatch) 
    end

    App.display.dispose

  end

  def add_menu_separator(menu=nil, index=nil)
    menu = @menu unless menu
    if index
      Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR, index)
    else
      Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR)
    end
  end

  def add_menu_item(label, selection_handler = nil, item_type =  Swt::SWT::PUSH, menu = nil, index = nil)
    menu = @menu unless menu
    if index
      menuitem = Swt::Widgets::MenuItem.new(menu, item_type, index)
    else
      menuitem = Swt::Widgets::MenuItem.new(menu, item_type)
    end

    menuitem.text = label
    if selection_handler
      menuitem.addListener(Swt::SWT::Selection, selection_handler ) 
    else
      menuitem.enabled = false
    end
    menuitem
  end

  def add_middleman_item(dir)
    if File.exists?(dir)
      menuitem = Swt::Widgets::MenuItem.new(@menu , Swt::SWT::PUSH, @menu.indexOf(@history_item) + 1 )
      menuitem.text = "#{dir}"
      menuitem.addListener(Swt::SWT::Selection, middleman_switch_handler)
      menuitem
    end
  end

  def empty_handler
    Swt::Widgets::Listener.impl do |method, evt|

    end
  end

  def clear_history
    @menu.items.each do |item|
      item.dispose if @history_dirs.include?(item.text)
    end
    @history_dirs = []
    App.clear_histoy
    build_history_menuitem
  end

  def middleman_switch_handler
    Swt::Widgets::Listener.impl do |method, evt|
      watch(evt.widget.text)
    end
  end

  def open_dir_handler
    Swt::Widgets::Listener.impl do |method, evt|
      if evt.widget.text =~ /^Stop/
        kill_thread
      else
        dia = Swt::Widgets::DirectoryDialog.new(@shell)
        watch(dia.open) 
      end
    end
  end


  def build_history_menuitem
    @menu.items.each do |item|
      item.dispose if @history_dirs.include?(item.text)
    end
    @history_dirs.reverse.each do | dir |
      add_middleman_item(dir)
    end
    App.set_histoy(@history_dirs[0,5])
  end

  def create_project_handler
    Swt::Widgets::Listener.impl do |method, evt|
      dia = Swt::Widgets::FileDialog.new(@shell,Swt::SWT::SAVE)
      dir = dia.open

      if dir 
        App.try do
          normal_dir(dir)
          stdout = `#{App::CONFIG["middleman_command"]["init"]} #{dir} -T #{evt.widget.text.downcase}`
          App.report( stdout.gsub!(/\x1B\[(?>(?>(?>\d+;)*\d+)?)m/,'') )
        end
      end
    end
  end

  def preference_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      PreferencePanel.instance.open
    end
  end

  def open_about_link_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      Swt::Program.launch('http://compass.handlino.com')
    end
  end

  def exit_handler
    Swt::Widgets::Listener.impl do |method, evt|
      App.set_histoy(@history_dirs[0,5])
      kill_thread
      sleep 1
      @shell.close
    end
  end

  def update_menu_position_handler 
    Swt::Widgets::Listener.impl do |method, evt|
      @menu.visible = true
    end
  end

  private

  def watch(dir)
    return unless dir
    normal_dir(dir)
    kill_thread 

    add_to_history(dir)
    Thread.abort_on_exception = true

    @watch_item.text="Stop watching " + dir
    Dir.chdir( dir )
    @tray_item.image = @watching_icon

    App.try do 
      @watch_pipe =  IO.popen("#{App::CONFIG["middleman_command"]["server"]} ") 
    end
  end

  def kill_thread
    @watch_thread.kill if @watch_thread && @watch_thread.alive?
    if @watch_pipe
      
      pid_exists = begin
          Process.getpgid( @watch_pipe.pid )
            true
      rescue Errno::ESRCH
          false
      end

      Process.kill("INT", @watch_pipe.pid) if pid_exists

      @watch_pipe = nil

    end
    @watch_item.text="Watch a Folder..."
    @tray_item.image = @standby_icon

  end

  def normal_dir(dir)
    dir.gsub!('\\','/') if org.jruby.platform.Platform::IS_WINDOWS
    File.expand_path(dir)
  end

  def add_to_history(dir)
    @history_dirs.delete_if { |x| x == dir }
    @history_dirs.unshift(dir)
    build_history_menuitem
  end
end


