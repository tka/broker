require 'singleton'

class PreferencePanel
  include Singleton

  def initialize()
    @display = Swt::Widgets::Display.get_current
  end

  def open
    self.create_window if !@shell || @shell.isDisposed
    m=@display.getPrimaryMonitor().getBounds()
    rect = @shell.getClientArea()
    @shell.setLocation((m.width-rect.width) /2, (m.height-rect.height) /2) 
    @shell.open
    @shell.forceActive
  end

  def create_window
    @shell = Swt::Widgets::Shell.new(@display, Swt::SWT::DIALOG_TRIM)
    @shell.setText("Preference")
    @shell.setBackgroundMode(Swt::SWT::INHERIT_DEFAULT)
    @shell.setSize(550,300)
    @shell.layout = Swt::Layout::FillLayout.new

    @tabFolder = Swt::Widgets::TabFolder.new(@shell, Swt::SWT::BORDER);

    history_tab = Swt::Widgets::TabItem.new( @tabFolder, Swt::SWT::NONE)
    history_tab.setControl( self.history_composite );
    history_tab.setText('History')

    @shell.pack
  end

  def history_composite
    composite =Swt::Widgets::Composite.new(@tabFolder, Swt::SWT::NO_MERGE_PAINTS );
    layout = Swt::Layout::GridLayout.new(1,true);
    composite.layout = layout
    
    label = Swt::Widgets::Label.new( composite, Swt::SWT::LEFT | Swt::SWT::WRAP)
    label.setText("We will list the last 10 folders in the history.\nIf you want to clean it, please click the button below.")

    clear_history_button = Swt::Widgets::Button.new(composite, Swt::SWT::PUSH )
    clear_history_button.setLayoutData( Swt::Layout::GridData.new(Swt::SWT::TOP, Swt::SWT::LEFT , false, false, 0, 0) )
    
    clear_history_button.text = "Clear History"
    clear_history_button.addListener(Swt::SWT::Selection, Swt::Widgets::Listener.impl do |method, evt| 
      Tray.instance.clear_history
      App.alert('done')
    end)
    composite
  end

end
