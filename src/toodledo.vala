/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * main.c
 * Copyright (C) Paulo Schreiner 2011 <paulo@jorjao81.com>
	 * 
 * toodledo is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
	 * 
 * toodledo is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Gtk;
using Soup;
using Json;
using Environment;
using Sqlite;
using Gee;
using AppIndicator;


[DBus (name = "im.pidgin.purple.PurpleInterface")]
interface Purple : GLib.Object {
	public signal void received_im_msg (int account, string sender, string msg,
	                                    int conv, uint flags);

	public abstract int[] purple_accounts_get_all_active () throws IOError;
	public abstract string purple_account_get_username (int account) throws IOError;

	public abstract int purple_savedstatus_new (string message, int status) throws IOError;
	public abstract void purple_savedstatus_activate(int status) throws IOError;
	public abstract void purple_savedstatus_set_message(int status, string s) throws IOError;
	public abstract int purple_savedstatus_get_current() throws IOError;
	public abstract void purple_savedstatus_set_type(int status, int tipo ) throws IOError;
}




public class ToodledoConfig : GLib.Object
{
	private string _lastedit_task = "";
	public string userid { get; set; }
	public string password { get; set; }
	public string key {get; set; }
	public int lastedit_task {get { if(_lastedit_task == "") { return 0; } else { return _lastedit_task.to_int(); }} set { _lastedit_task = @"$value"; } }
	public string database_file {get; set; default = Environment.get_home_dir() +"/.toodledo/toodledo.sqlite"; }
	public static string base_dir {get; set; default = Environment.get_home_dir() + "/toodledo"; }

	public ToodledoConfig() {
		get_from_file();
	}

	private void get_from_file() {
		var file = File.new_for_path(Environment.get_home_dir() + @"/.toodledo/config");

		try {
			stdout.printf("get from file\n");
			// Open file for reading and wrap returned FileInputStream into a
			// DataInputStream, so we can read line by line
			int i = 0;
			var dis = new DataInputStream (file.read ());
			string line;
			// Read lines until end of file (null) is reached
			while ((line = dis.read_line (null)) != null) {
				if(i == 0) {
					userid = line;
				}
				else if(i == 1) {
					password = line;
				}
				else if(i == 2) {
					key = line;
					stdout.printf("key %s\n", key);
				}
				else if(i == 3) {
					_lastedit_task = line;
				}
				i++;
			}
		} catch (Error e) {
			error ("%s", e.message);
		}        
	}

	public void write_to_file() {
		var file = File.new_for_path(Environment.get_home_dir() + @"/.toodledo/config");
		var stream = file.replace(null, false, 0,null);
		var data =  @"$userid\n$password\n$key\n$(lastedit_task)\n".to_utf8();
		stream.write(((uint8 [])data), null);
		stream.close (null);
	}

	~ToodledoConfig() {
		stdout.printf("in destructor\n");
		write_to_file();
	}
}

public class ToodledoTask : GLib.Object
{
	private int64 _duetime;
	private DateTime __duetime;
	private int64 _completed;
	private DateTime __completed;
	public string title { get; set; default = ""; } // TODO encode the & character as %26 and the ; character as %3B
	public string tag { get; set; default = "";} // TODO ncode the & character as %26 and the ; character as %3B.
	public int64 folder { get; set; default = 0; }
	public int64 id { get; set; default = 0; }
	public int64 context { get; set; default = 0; }
	public int64 goal { get; set; default = 0; }
	public int64 location { get; set; default = 0; }
	public int64 parent { get; set; default = 0; }
	public int64 children { get; set; default = 0; }
	//public int order { get; set; }
	public int64 duedate {get; set; default = 0; }
	public int64 duedatemod {get; set; default = 0; }
	public DateTime duetime {
		get { __duetime = new DateTime.from_unix_utc(_duetime); return __duetime; }
		set { _duetime = value.to_unix(); }}
	public int64 startdate {get; set; default = 0; }
	public int64 starttime {get; set; default = 0; }
	public int64 remind {get; set; default = 0; }
	public string repeat {get; set; default = ""; }
	public int64 repeatfrom {get; set; default = 0; }
	public int64 status {get; set; default = 0; }
	public int64 length {get; set; default = 0; }
	public int64 priority {get; set; default = 1; }
	public int64 star {get; set; default = 0; }
	public int64 modified {get; set; default = 0; }	
	public DateTime completed {
		get { __completed = new DateTime.from_unix_utc(_completed); return __completed; }
		set { _completed = value.to_unix(); }}	
	public int64 added {get; set; default = 0; }	
	public int64 timer {get; set; default = 0; }	
	public string note {get; set; default = ""; }

	public weak ToodledoConfig config {get; set; }
	public weak Toodledo toodledo { get; set; }

	public ToodledoTask() {
	}



	public int time_expended() {
		/* returns the time actually expended in minutes 
		 * if TIMER contains something, use that value, else
		 * use predicted task length */
		if(timer > 0) {
			return (int)timer/60;
		}
		else {
			if (completed.to_unix() > 0) {
				return (int)length;
			}
			else { return 0; }
		}
	}

	public ToodledoTask.from_array(string[] arr, Toodledo t, ToodledoConfig c) {
		_id = arr[0].to_int();
		_title = arr[1];
		_tag = arr[2];
		_folder = arr[3].to_int();
		_context = arr[4].to_int();
		_goal = arr[5].to_int();
		_location = arr[6].to_int();
		_children = arr[7].to_int();
		_duedate = arr[8].to_int();
		_duedatemod = arr[9].to_int();
		_duetime = arr[10].to_int();
		_starttime = arr[11].to_int();
		_remind = arr[12].to_int();
		_repeat = arr[13];
		_repeatfrom = arr[14].to_int();
		_status = arr[15].to_int();
		_length = arr[16].to_int();
		_priority = arr[17].to_int();
		_star = arr[18].to_int();
		_modified = arr[19].to_int();
		_completed = arr[20].to_int();
		_added = arr[21].to_int();
		_timer = arr[22].to_int();
		_note = arr[23];

		toodledo = t;
		config = c;
	}

	public string foldername() {
		var folder = ToodledoFolder.mapa[(int)folder];
		var foldername = folder.name;
		return foldername;
	}

	public void print () {
		stdout.printf("%i\n", (int)folder);
		var folder = ToodledoFolder.mapa[(int)folder];
		var foldername = folder.name;		
		//stdout.printf(@"$foldername\n");
		stdout.printf(@"$(id): $(title)\n%s\n%s\n%i\ntime expended: $(time_expended ()) min\nfolder: $(foldername)\tgoal: %i\tpriority: %i\n------------------\n\n", duetime.to_string(), completed.to_string(), modified, goal, priority);
	}
	public void print2 (Gee.Map<int, ToodledoFolder> mapa) {
		var foldername = mapa[(int)id].name;
		stdout.printf(@"$foldername\n");
		//stdout.printf(@"$(id): $(title)\n%s\n%s\n%i\ntime expended: %i min\nfolder: %s\tgoal: %i\tpriority: %i\n------------------\n\n", duetime.to_string(), completed.to_string(), modified, time_expended (), ToodledoFolder.map[(int)folder].name, goal, priority);
	}


	public ToodledoTask.from_json(Json.Object task, Toodledo t, ToodledoConfig c) {

		_title = task.get_string_member("title");
		_tag = task.get_string_member("tag");
		_repeat = task.get_string_member("repeat");
		_note = task.get_string_member("note");
		_id = json_get_integer(task, "id");

		_duedate = json_get_integer (task, "duedate");
		_duetime = json_get_integer(task, "duetime");
		_folder = json_get_integer(task, "folder");		
		_context = json_get_integer (task, "context");
		_goal = json_get_integer (task, "goal");
		_location = json_get_integer (task, "location");
		_duedatemod = json_get_integer (task, "duedatemod");
		_startdate = json_get_integer (task, "startdate");
		_starttime = json_get_integer (task, "starttime");
		_remind = json_get_integer (task, "remind");
		_repeatfrom = json_get_integer (task,"repeatfrom");
		_status = json_get_integer (task, "status");
		_length = json_get_integer (task, "length");
		_priority = json_get_integer (task, "priority");
		_star = json_get_integer (task, "star");
		_modified = json_get_integer (task, "modified");
		_completed = json_get_integer (task, "completed");
		_added = json_get_integer (task, "added");
		_timer = json_get_integer (task, "timer");

		toodledo = t;
		config = c;
	}

	public static int json_get_integer(Json.Object o, string member) {
		int v1, v2;
		if((!o.has_member(member)) || o.get_null_member(member)) {
			return 0;
		}
		v1 = (int)o.get_int_member(member);
		if(!(o.get_string_member(member) == null) || (o.get_string_member(member) == "")) {
			v2 = o.get_string_member(member).to_int();
		}
		else { v2 =0 ; }
		if(v2 > v1) {
			return v2;
		}
		else {
			return v1;
		}
	}

	private string escape(string s) {
		return s.replace("'", "''");
	}

	public bool save_to_sqlite() {
		Database db;

		if (!FileUtils.test (config.database_file, FileTest.IS_REGULAR)) {
			stderr.printf ("Database %s does not exist or is directory\n", config.database_file);
			return false;
		}

		var rc = Database.open (config.database_file, out db);

		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
			return false;
		}
		
		var etitle = escape(_title);
		var etag = escape(_tag);
		var enote = escape(_note);
		rc = db.exec(@"DELETE FROM TASKS WHERE id = $id; INSERT INTO tasks VALUES ($(_id), \'$(etitle)\', \'$(etag)\', $(_folder), $(_context), $(_goal), $(_location), $(_children), $(_duedate), $(_duedatemod), $(_duetime), $(_starttime), $(_remind), \'$(_repeat)\', $(_repeatfrom), $(_status), $(_length), $(_priority), $(_star), $(_modified), $(_completed), $(_added), $(_timer), \'$(enote)\')", null, null);

		if (rc != Sqlite.OK) { 
			stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
			return false;
		}

		/* update lastedit */
		if (_modified > config.lastedit_task) {
			config.lastedit_task = (int)_modified;
		}

		return true;

	}

	public void save_both() {
		save_to_sqlite();
		save_to_toodledo ();
	}
		

	public void save_to_toodledo() {
		var build = new Json.Builder();

		build.begin_array();
		build.begin_object();
		build.set_member_name("id");
		build.add_int_value(_id);
		build.set_member_name("timer");
		build.add_int_value(_timer);
		build.end_object ();
		build.end_array();

		

		var gen = new Json.Generator();
		gen.set_root (build.get_root());

		size_t length;
		string data = gen.to_data(out length);

		stdout.printf("%s\n", data);

		var key = config.key;
		var url = @"http://api.toodledo.com/2/tasks/edit.php?key=$key;tasks=$data;fields=timer";

			stdout.printf("%s\n", url);
		// create an HTTP session to twitter
		var session = new Soup.SessionAsync ();
		var message = new Soup.Message ("GET", url);

		// send the HTTP request
		session.send_message (message);

		var parser = new Json.Parser ();
		parser.load_from_data ((string) message.response_body.flatten ().data, -1);
		Json.Object root_object = parser.get_root().get_object();
		
		int error = 0;
		if ((error = (int)root_object.get_int_member ("errorCode")) == 2) {
		// TODO: Refactor this mess, keep it DRY
			stdout.printf("Error %i\n", error);
			stdout.printf("Old key: %s\n", config.key);
			config.key = toodledo.get_key();
			stdout.printf("New key: %s\n", config.key);
			url = @"http://api.toodledo.com/2/tasks/edit.php?key=$key;tasks=$data;fields=timer";
			message = new Soup.Message("GET", url);
			session.send_message (message);
			parser.load_from_data ((string) message.response_body.flatten ().data, -1);
			root_object = parser.get_root ().get_object ();
		}


		stdout.printf("%s\n", (string) message.response_body.flatten ().data);


		//config.send_json("http://api.toodledo.com/2/tasks/edit.php?", jset);
		
	}

}	


public class Toodledo : GLib.Object
{
	private string userid;
	private string password;
	private string appid;	
	private string apptoken;
	public int lastedit_task;
	public ToodledoConfig t_config;
	public HashMap<int,ToodledoFolder> folders;

	private string get_session_token() {
		size_t size = (userid + apptoken).length;
		var md5 =GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, userid 
		                                           + apptoken, size); 

		var url = @"http://api.toodledo.com/2/account/token.php?userid=$(userid);appid=$(appid);
		vers=1;sig=$(md5)";
		stdout.printf("get_session_token()\nurl:%s\n", url);

		// create an HTTP session to twitter
		var session = new Soup.SessionAsync ();
		var message = new Soup.Message ("GET", url);

		// send the HTTP request
		session.send_message (message);

		var parser = new Json.Parser ();
		parser.load_from_data ((string) message.response_body.flatten ().data, -1);
		stdout.printf("%s\n", (string) message.response_body.flatten ().data);

		Json.Object root_object = parser.get_root().get_object();

		var token2 = root_object.get_string_member("token");

		return token2;
	}

	public string get_key() {
		stdout.printf("get key\n");
		var sessiontoken = get_session_token();
		var temp = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, password, password.length)
			+ apptoken + sessiontoken;

		var key = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, temp, temp.length);
		return key;
	}


	private Json.Object get_json(string url) {
		// try to connect with old key
		var session = new Soup.SessionAsync ();

		var message = new Soup.Message("GET", url + t_config.key);
		session.send_message (message);
		var parser = new Json.Parser ();
		parser.load_from_data ((string) message.response_body.flatten ().data, -1);
		var root_object = parser.get_root ().get_object ();

		int error;
		if ((error = (int)root_object.get_int_member ("errorCode")) == 2) {
			stdout.printf("Error %i\n", error);
			stdout.printf("Old key: %s\n", t_config.key);
			t_config.key = get_key();
			stdout.printf("New key: %s\n", t_config.key);
			message = new Soup.Message("GET", url + t_config.key);
			session.send_message (message);
			parser.load_from_data ((string) message.response_body.flatten ().data, -1);
			root_object = parser.get_root ().get_object ();
		}


		return root_object;
	}

	public Gee.List<ToodledoTask> all_tasks_after(int after) {
		var l = new Gee.ArrayList<ToodledoTask> ();

		// pegar tarefas
		var session = new Soup.SessionAsync ();
		var url = @"http://api.toodledo.com/2/tasks/get.php?modafter=$(after);fields=folder,context,goal,location,tag,startdate,duedate,duedatemod,starttime,duetime,remind,repeat,status,star,priority,length,timer,added,note,parent,children,order;key=";
			var message = new Soup.Message("GET", url + t_config.key);
		session.send_message (message);
		var parser = new Json.Parser ();
		parser.load_from_data ("{\"tarefas\" : " + (string) message.response_body.flatten ().data + "}", -1);
		var troot_object = parser.get_root ().get_object ();

		var first = true;
		foreach (var node in troot_object.get_array_member("tarefas").get_elements ()) {
			if(first) { first = false; }
			else {
				var geoname = node.get_object ();
				var task = new ToodledoTask.from_json(geoname, this, t_config);
				task.config = t_config;
				l.add(task);
			}
		}
		//stdout.printf("%s\n", (string) message.response_body.flatten ().data);
		stdout.printf("after: %i\n", after);
		return l;
	}

	public Gee.List<ToodledoFolder> all_folders() {
		var l = new Gee.ArrayList<ToodledoFolder> ();

		// pegar tarefas
		var session = new Soup.SessionAsync ();
		var url = @"http://api.toodledo.com/2/folders/get.php?key=";
			var message = new Soup.Message("GET", url + t_config.key);
		session.send_message (message);
		var parser = new Json.Parser ();
		parser.load_from_data ("{\"tarefas\" : " + (string) message.response_body.flatten ().data + "}", -1);
		stdout.printf ("{\"tarefas\" : " + (string) message.response_body.flatten ().data + "}\n");
		var troot_object = parser.get_root ().get_object ();

		var first = false;
		foreach (var node in troot_object.get_array_member("tarefas").get_elements ()) {
			if(first) { first = false; }
			else {
				var geoname = node.get_object ();
				var folder = new ToodledoFolder.from_json(geoname);
				//task.config = t_config;
				l.add(folder);
				folders[folder.id] = folder;
			}
		}
		//stdout.printf("%s\n", (string) message.response_body.flatten ().data);
		//stdout.printf("after: %i\n", after);
		folders[0] = new ToodledoFolder();
		folders[0].name = "None";
		ToodledoFolder.mapa = folders;
		return l;
	}

	public Gee.List<ToodledoTask> all_tasks() {
		return all_tasks_after(0);
	}

	public Toodledo(ToodledoConfig c) {
		userid = c.userid;
		password = c.password;
		appid = "jorjao81teste";
		apptoken = "api4e369a29d9473";
		t_config = c;

		folders = new HashMap<int,ToodledoFolder>();

		// connect to toodledo
		var url = @"http://api.toodledo.com/2/account/get.php?key=";
			var root = get_json(url);

		userid = root.get_string_member ("userid");
		stdout.printf("Userid: %s\n", userid);

		var alias = root.get_string_member ("alias");
		stdout.printf("alias: %s\n", alias);

		lastedit_task = ToodledoTask.json_get_integer (root, "lastedit_task");
		stdout.printf("Lastedit task: %i\n", lastedit_task);
	}

	public Gee.List<ToodledoTask> from_sqlite(string arg) {
		var l = new ArrayList<ToodledoTask> ();

		var c = t_config;

		Database db;

		if (!FileUtils.test (t_config.database_file, FileTest.IS_REGULAR)) {
			stderr.printf ("Database %s does not exist or is directory\n", t_config.database_file);
			return null;
		}

		var rc = Database.open (t_config.database_file, out db);

		if (rc != Sqlite.OK) {
			stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
			return null;
		}
		rc = db.exec(@"SELECT * FROM tasks $(arg)", (n_collumns, values, collumn_names) => { 
			var t = new ToodledoTask.from_array (values, this, t_config);
			t.config = c;
			l.add(t); return 0;}, null);

		if (rc != Sqlite.OK) { 
			stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
			return null;
		}



		return l;

	}


}



public class Main : GLib.Object 
{

	/* 
	 * Uncomment this line when you are done testing and building a tarball
	 * or installing
	 */
	//const string UI_FILE = Config.PACKAGE_DATA_DIR + "/" + "gtk_foobar.ui";
	const string UI_FILE = "src/gtk_foobar.ui";

	public static int default_length;
	public static int minutes_left;
	// when a pomodoro is finished, contains minus (-) the minutes left: 0 in case the time ran out
	public static int total_pomodoros;
	public static Indicator indicator;


	public Main ()
	{


		try 
		{
			var builder = new Gtk.Builder ();
			builder.add_from_file (UI_FILE);
			builder.connect_signals (this);

			var window = builder.get_object ("window") as Window;
			window.show_all ();
		} 
		catch (Error e) {
			stderr.printf ("Could not load UI: %s\n", e.message);
		} 

	}

	[CCode (instance_pos = -1)]
	public void on_destroy (Widget window) 
	{
		Gtk.main_quit();
	}

	static string pretty_time(int minutes) {
		if(minutes < 60) {
			return @"$(minutes)min";
		}
		else {
			return @"$(minutes/60)h $(minutes%60)min";
		}
	}

	static void pomodoro_start(Purple purple, ToodledoTask task) {
		stdout.printf("Pomodoro start\n");
		if(minutes_left <= default_length) {
			return;
		}
		stdout.printf("Pomodoro start 2\n");
		try {
			stdout.printf("Pomodoro start 3\n");
			minutes_left--;
			var status = purple.purple_savedstatus_get_current();
			purple.purple_savedstatus_set_message(status, @"Pomodoro: $minutes_left min restando");
			purple.purple_savedstatus_set_type(status, 3);
			purple.purple_savedstatus_activate(status);

			indicator.set_status(IndicatorStatus.ATTENTION);
			stdout.printf("Pomodoro start 4\n");
			GLib.Timeout.add_seconds(60, () => {
				stdout.printf(@"timeout $minutes_left\n");
				minutes_left--;
				var status2 = purple.purple_savedstatus_get_current();

				if(minutes_left > 0) {
					purple.purple_savedstatus_set_message(status2, @"Pomodoro: $minutes_left min restando");
					purple.purple_savedstatus_set_type(status2, 3);
					purple.purple_savedstatus_activate(status2);
					return true;
				}
				else {
					finish_pomodoro(purple, task);
					return false;
				}
			});
		} catch (IOError e) {
			stderr.printf ("%s\n", e.message);
		}
	}

	static void finish_pomodoro(Purple purple, ToodledoTask task) {
		stdout.printf("finish_pomodoro ()\n");
		if(minutes_left == 0) {
			total_pomodoros++;
			if((total_pomodoros % 8) == 0) {
				notify_osd(@"Pomodoro finished", 
				           @"Congratulations!!! You finished your 8th pomodoro. You may nopw take a long break, like lunch.", 0);
			}
			else if((total_pomodoros % 4) == 0) {
				notify_osd(@"Pomodoro finished", 
				           @"Congratulations! You finished your 4th pomodoro. You should now take a longer brak, ~15min", 0);
			}
			else {
				notify_osd(@"Pomodoro $total_pomodoros finished", 
				           @"You should now take a short break", 0);
			}
			Posix.system("mpg321 " + ToodledoConfig.base_dir + "/icons/Apple_3g_Ring.mp3");
		}
	
		if(minutes_left == 0) {
			task.timer = task.timer + (30)*60;
		}
		else {			
			task.timer = task.timer + (default_length + minutes_left + 1)*60; // yes, its + minutes_left
		}
		minutes_left = default_length + 1;
		indicator.set_status(IndicatorStatus.ACTIVE);
		task.save_both ();
		try {
			var status = purple.purple_savedstatus_get_current();
			purple.purple_savedstatus_set_message(status, @"");
			purple.purple_savedstatus_set_type(status, 2);
			purple.purple_savedstatus_activate(status);
			stdout.printf("finish 2\n");
		} catch (IOError e) {
			stderr.printf ("%s\n", e.message);
		}
	}


	static void notify_osd(string title, string text, int icon) {
		var icon_text = ToodledoConfig.base_dir + "/icons/green-tomato.svg";
		string tip = "Tell your friends all about Pomodoro. They will tend to interrupt you less during your pomodori, and might even become converts!";
		if(icon == 1) {
			icon_text = ToodledoConfig.base_dir + "/icons/pomodoro.jpeg";
		}
		if(icon == 2) {
			icon_text = ToodledoConfig.base_dir + "/icons/angry_tomato.jpeg";
			text = "Damn those interruptions. How will you achieve Master Tomatoman if people keep interrupting you?";
		}
		
		Posix.system(@"notify-send '$title' '$text TIP: $tip' -i $icon_text");
	}
		


	static int main (string[] args) 
	{
		Gtk.init (ref args);
		
		var app = new Main ();

		default_length = 25;
		minutes_left = default_length + 1;
		total_pomodoros = 0;

		Purple purple;
		try {
			purple = Bus.get_proxy_sync (BusType.SESSION,
			                             "im.pidgin.purple.PurpleService",
			                             "/im/pidgin/purple/PurpleObject");
			var accounts = purple.purple_accounts_get_all_active ();
			foreach (int account in accounts) {
				string username = purple.purple_account_get_username (account);
				stdout.printf ("Account %s\n", username);
			}

			purple.received_im_msg.connect ((account, sender, msg) => {
				stdout.printf (@"Message received $sender: $msg\n");
			});
		}
		catch (IOError e) {
			return 1;
		}

		var c = new ToodledoConfig();		
		var t = new Toodledo(c);

		var map = new HashMap<string, int> ();
		t.all_folders (); /* to initialize id -> folder mapping */
		foreach (var s in t.folders.keys) {
			stdout.printf (@"%i - $(t.folders[s].name)\n", s);
			map[t.folders[s].name] = 0; // inicializar
		}

		if(args[1] == "--from-server") { 
			var l = t.all_tasks();
			foreach(var task in l) {
				task.print();
			}
		}
		else if(args[1] == "--overwrite-from-server") { 
			Database db;
			if (!FileUtils.test (c.database_file, FileTest.IS_REGULAR)) {
				stderr.printf ("Database %s does not exist or is directory\n", c.database_file);
				return 1;
			}

			var rc = Database.open (c.database_file, out db);

			if (rc != Sqlite.OK) {
				stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
				return 1;
			}

			rc = db.exec(@"DELETE from tasks;", null, null);

			if (rc != Sqlite.OK) { 
				stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
				return 1;
			}

			var l = t.all_tasks();
			foreach(var task in l) {
				task.print();
				task.save_to_sqlite();
			}
		}		
		else if(args[1] == "--indicator") {
		notify_osd(@"Welcome to pomodoro!", 
				           @"", 1);
			var n = t.all_tasks_after(c.lastedit_task);
			foreach(var task in n) {
				task.print();
				task.save_to_sqlite();
			}
			//stdout.printf("%i\n", c.lastedit_task);


			var win = new Window();
			win.title = "Indicator Test";
			win.resize(200, 200);
			win.destroy.connect(Gtk.main_quit);

			indicator = new Indicator(win.title, "green-tomato",
			                          IndicatorCategory.APPLICATION_STATUS);
			indicator.set_status(IndicatorStatus.ACTIVE);
			indicator.set_icon_theme_path(ToodledoConfig.base_dir + "/icons");
			indicator.set_attention_icon("red-tomato");


			var menu = new Menu();

			var l = t.from_sqlite ("");

			//stdout.printf("Teste\n");

			var now = new DateTime.now_utc();
			int total_time = 0;


			foreach (var task in l) {
				//		   stdout.printf("%i %i\n", (int32)task.duedate, (int32)now.to_unix());
				if((task.duedate > now.add_days(-1).to_unix()) && (task.duedate < now.to_unix())
				   && (task.completed.to_unix() == 0)) {
					   task.print();
					   //stdout.printf("%i %i\n", (int32)task.duedate, (int32)now.to_unix());

					   var item = new MenuItem.with_label(task.title);
					   item.activate.connect(() => {
						   pomodoro_start(purple, task);
					   });
					   item.show();
					   menu.append(item);

				   }
			}

			var item = new SeparatorMenuItem();
			item.show();
			menu.append(item);

			var item2 = new ImageMenuItem.from_stock (Gtk.STOCK_MEDIA_STOP, null);
			item2.set_label("Void Pomodoro");
			item2.show();
			menu.append(item2);
			item2.activate.connect(() => {
				minutes_left = -minutes_left;
				notify_osd(@"Interrupted!", 
				           "", 2);
				var status = purple.purple_savedstatus_get_current();
				purple.purple_savedstatus_set_message(status, @"");
				purple.purple_savedstatus_set_type(status, 2);
				purple.purple_savedstatus_activate(status);
				indicator.set_status(IndicatorStatus.ACTIVE);
			});

			var item3 = new ImageMenuItem.from_stock (Gtk.STOCK_MEDIA_STOP, null);
			item3.set_label("Quit");
			item3.show();
			menu.append(item3);
			item3.activate.connect(() => {
				if(minutes_left == default_length + 1) {
					// no pomodoro running, safe to quit 
					Gtk.main_quit();
				}
			});


			indicator.set_menu(menu);


			//win.show_all();

			Gtk.main();
		}
		else if(args[1] == "--folders") {
			stdout.printf("FOLDERS\n");
			var l = t.all_folders ();
			foreach(var f in l) {
				f.print();
			}
		}
		else {

			var l = t.from_sqlite (args[1]);

			stdout.printf("Teste\n");

			var now = new DateTime.now_utc();
			int total_time = 0;


			foreach (var task in l) {
				if((task.completed.to_unix() > (now.add_days(-7)).to_unix())
				   || (task.completed.to_unix() == 0)) {

					   task.print();
					   map[task.foldername()] = map[task.foldername()] + task.time_expended();
					   total_time += task.time_expended();
				   }
			}
			foreach (var entry in map.entries) {
				stdout.printf ("%s => %d min\n", entry.key, entry.value);
			}
			stdout.printf("\n\nTotal time %s\n", pretty_time(total_time));

		}
		t = null;
		c = null;
		stdout.printf("FIM!\n");
		return 0;
	}
}
