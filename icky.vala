using Posix;

public class IckySticky : Gtk.Application {
  private string button_label;
  private const string SOCKET_PATH = "/tmp/icky-daemon.sock";
  private const string PID_FILE = "/tmp/icky-daemon.pid";
  private SocketService? socket_service;
  private bool is_daemon = false;

  public IckySticky (string button_label) {
    Object (
      application_id: "icky.sticky",
      flags: ApplicationFlags.HANDLES_COMMAND_LINE | ApplicationFlags.NON_UNIQUE
    );
    this.button_label = button_label;
  }

  private void show_window () {
    var win = new Gtk.ApplicationWindow (this);
    win.set_name("icky-sticky");
    win.set_default_size(100, 100);

    // css
    var provider = new Gtk.CssProvider();
    provider.load_from_string("""
      window#icky-sticky {
        background-color: rgba(0, 0, 0, 0);
        background-image: none;
      }
      window#icky-sticky > * {
        background-color: rgba(0, 0, 0, 0);
      }
      #sticky-icky {
        font-size: 30pt;
        font-family: "Boxcutter";
        background-color: rgba(0, 0, 0, 0);
        background-image: none;
      }
    """);

    Gtk.StyleContext.add_provider_for_display(win.get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

    var btn = new Gtk.Button.with_label(this.button_label);
    btn.set_name("sticky-icky");

    // click on close, disable
    // btn.clicked.connect (win.close);

    win.set_child(btn);
    win.present();
  }

  public override void activate () {
    if (is_daemon) {
      start_daemon();
      hold();
    } else {
      show_window();
    }
  }

  private void start_daemon () {
    try {
      socket_service = new SocketService();

      if (FileUtils.test(SOCKET_PATH, FileTest.EXISTS)) {
        FileUtils.unlink(SOCKET_PATH);
      }

      var socket_address = new UnixSocketAddress(SOCKET_PATH);
      socket_service.add_address(socket_address, SocketType.STREAM, SocketProtocol.DEFAULT, null, null);
      socket_service.incoming.connect(on_incoming_connection);
      socket_service.start();

      write_pid_file();
      print("Icky daemon started\n");
    } catch (Error e) {
      GLib.stderr.printf("Error starting daemon: %s\n", e.message);
    }
  }

  private bool on_incoming_connection (SocketConnection connection, Object? source_object) {
    try {
      var input_stream = new DataInputStream(connection.input_stream);
      var message = input_stream.read_line();

      if (message != null && message.length > 0) {
        Idle.add(() => {
          this.button_label = message;
          show_window();
          return false;
        });
      }
    } catch (Error e) {
      GLib.stderr.printf("Error handling connection: %s\n", e.message);
    }
    return false;
  }

  private void write_pid_file () {
    try {
      var file = File.new_for_path(PID_FILE);
      var output_stream = file.create(FileCreateFlags.REPLACE_DESTINATION);
      var data_stream = new DataOutputStream(output_stream);
      data_stream.put_string(((int)Posix.getpid()).to_string());
      output_stream.close();
    } catch (Error e) {
      GLib.stderr.printf("Error writing PID file: %s\n", e.message);
    }
  }

  public override int command_line (ApplicationCommandLine cmd) {
    string[] args = cmd.get_arguments();

    if (args.length > 1) {
      if (args[1] == "stop") {
        if (is_daemon_running()) {
          stop_daemon();
          print("Daemon stopped\n");
        } else {
          print("Daemon is not running\n");
        }
        return 0;
      } else {
        if (is_daemon_running()) {
          send_note_to_daemon(args[1]);
          return 0;
        } else {
          this.button_label = args[1];
          this.is_daemon = true;
          this.activate();
          Idle.add(() => {
            show_window();
            return false;
          });
          return 0;
        }
      }
    } else {
      if (is_daemon_running()) {
        print("Daemon is already running\n");
        return 0;
      } else {
        this.button_label = "Buy Milk";
        this.is_daemon = true;
        this.activate();
        return 0;
      }
    }
  }

  private bool is_daemon_running () {
    if (!FileUtils.test(PID_FILE, FileTest.EXISTS)) {
      return false;
    }

    try {
      string pid_content;
      FileUtils.get_contents(PID_FILE, out pid_content);
      pid_t pid = (pid_t)int.parse(pid_content.strip());

      if (Posix.kill((Posix.pid_t)pid, 0) == 0) {
        return true;
      } else {
        FileUtils.unlink(PID_FILE);
        if (FileUtils.test(SOCKET_PATH, FileTest.EXISTS)) {
          FileUtils.unlink(SOCKET_PATH);
        }
        return false;
      }
    } catch (Error e) {
      return false;
    }
  }

  private void send_note_to_daemon (string note) {
    try {
      var socket_client = new SocketClient();
      var socket_address = new UnixSocketAddress(SOCKET_PATH);
      var connection = socket_client.connect(socket_address);

      var output_stream = new DataOutputStream(connection.output_stream);
      output_stream.put_string(note + "\n");
      output_stream.close();
      connection.close();
    } catch (Error e) {
      GLib.stderr.printf("Error sending note to daemon: %s\n", e.message);
    }
  }

  private void stop_daemon () {
    try {
      string pid_content;
      if (FileUtils.get_contents(PID_FILE, out pid_content)) {
        pid_t pid = (pid_t)int.parse(pid_content.strip());
        Posix.kill((Posix.pid_t)pid, Posix.Signal.TERM);

        // Clean up files
        if (FileUtils.test(PID_FILE, FileTest.EXISTS)) {
          FileUtils.unlink(PID_FILE);
        }
        if (FileUtils.test(SOCKET_PATH, FileTest.EXISTS)) {
          FileUtils.unlink(SOCKET_PATH);
        }
      }
    } catch (Error e) {
      GLib.stderr.printf("Error stopping daemon: %s\n", e.message);
    }
  }

  public static int main (string[] args) {
    var app = new IckySticky ("Buy Milk");

    Posix.signal(Posix.Signal.TERM, cleanup_on_exit);
    Posix.signal(Posix.Signal.INT, cleanup_on_exit);

    return app.run (args);
  }

  private static void cleanup_on_exit (int sig) {
    if (FileUtils.test(PID_FILE, FileTest.EXISTS)) {
      FileUtils.unlink(PID_FILE);
    }
    if (FileUtils.test(SOCKET_PATH, FileTest.EXISTS)) {
      FileUtils.unlink(SOCKET_PATH);
    }
    Posix.exit(0);
  }
}
