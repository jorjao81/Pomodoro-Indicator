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

public class ToodledoConfig : GLib.Object
{
	public string userid { get; set; }
	public string password { get; set; }
	public string key {get; set; }
	public string database_file {get; set; default = Environment.get_home_dir() +"/.toodledo/toodledo.sqlite"; }

	public ToodledoConfig() {
		get_from_file();
	}

	private void get_from_file() {
		 var file = File.new_for_path(Environment.get_home_dir() + @"/.toodledo/config");
		
		 try {
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
		var data =  @"$userid\n$password\n$key\n".to_utf8();
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
	public int64 completed {get; set; default = 0; }	
	public int64 added {get; set; default = 0; }	
	public int64 timer {get; set; default = 0; }	
	public string note {get; set; default = ""; }

	private static string database {get; set; default = "/home/paulo/.toodledo/toodledo.sqlite"; } 

	private ToodledoConfig config;

	public ToodledoTask() {
	}

	public static Gee.List<ToodledoTask> from_sqlite() {
		var l = new ArrayList<ToodledoTask> ();

		database = "/home/paulo/.toodledo/toodledo.sqlite";
		
		Database db;

		if (!FileUtils.test (database, FileTest.IS_REGULAR)) {
            stderr.printf ("Database %s does not exist or is directory\n", database);
            return null;
        }

        var rc = Database.open (database, out db);

		if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            return null;
        }
		rc = db.exec(@"SELECT * FROM tasks", (n_collumns, values, collumn_names) => { 
			var t = new ToodledoTask.from_array (values);
			l.add(t); return 0;}, null);

		if (rc != Sqlite.OK) { 
            stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
            return null;
        }

	

		return l;
		
	}

	public ToodledoTask.from_array(string[] arr) {
		_id = arr[0].to_int();
		_title = arr[1];
		_tag = arr[2];
		_folder = arr[3].to_int();
		_context = arr[4].to_int();
		_goal = arr[5].to_int();
		_location = arr[6].to_int();
		_children = arr[7].to_int();
		_duedate = arr[8].to_int();
		_duetime = arr[9].to_int();
		_starttime = arr[10].to_int();
		_remind = arr[11].to_int();
		_repeat = arr[12];
		_repeatfrom = arr[12].to_int();
		_status = arr[13].to_int();
		_length = arr[14].to_int();
		_priority = arr[15].to_int();
		_star = arr[16].to_int();
		_modified = arr[17].to_int();
		_completed = arr[18].to_int();
		_added = arr[19].to_int();
		_timer = arr[20].to_int();
		_note = arr[21];
	}

	public void print () {
		stdout.printf(@"$(id): $(title)\n%s\nfolder: %i\tgoal: %i\tpriority: %i\n------------------\n\n", duetime.to_string(), folder, goal, priority);
	}
		 
	
	public ToodledoTask.from_json(Json.Object task) {
		
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
	}

	public int json_get_integer(Json.Object o, string member) {
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
		


	public bool save_to_sqlite() {
		Database db;

		if (!FileUtils.test (database, FileTest.IS_REGULAR)) {
            stderr.printf ("Database %s does not exist or is directory\n", database);
            return false;
        }

        var rc = Database.open (database, out db);

		if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            return false;
        }
		rc = db.exec(@"INSERT INTO tasks VALUES ($(_id), \"$(_title)\", \"$(_tag)\", $(_folder), $(_context), $(_goal), $(_location), $(_children), $(_duedate), $(_duedatemod), $(_duetime), $(_starttime), $(_remind), \"$(_repeat)\", $(_repeatfrom), $(_status), $(_length), $(_priority), $(_star), $(_modified), $(_completed), $(_added), $(_timer), \"$(_note)\")", null, null);

		if (rc != Sqlite.OK) { 
            stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
            return false;
        }

		return true;

	}

}	
		

public class Toodledo : GLib.Object
{
	private string userid;
	private string password;
	private string appid;	
    private string apptoken;
	public ToodledoConfig t_config;

	private string get_session_token() {
		size_t size = (userid + apptoken).length;
		var md5 =GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, userid 
		                                       + apptoken, size); 

var url = @"http://api.toodledo.com/2/account/token.php?userid=$(userid);appid=$(appid);
vers=1;sig=$(md5)";

		// create an HTTP session to twitter
    var session = new Soup.SessionAsync ();
    var message = new Soup.Message ("GET", url);

    // send the HTTP request
    session.send_message (message);

    // output the XML result to stdout 
    stdout.write (message.response_body.data);
	stdout.printf("\n");
		
		   var parser = new Json.Parser ();
        parser.load_from_data ((string) message.response_body.flatten ().data, -1);

        Json.Object root_object = parser.get_root().get_object();
		var user_pw = "Agatha84";

		var token2 = root_object.get_string_member("token");

		return token2;
}

	private string get_key() {
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
			t_config.key = get_key();
			message = new Soup.Message("GET", url + t_config.key);
			session.send_message (message);
		   	parser.load_from_data ((string) message.response_body.flatten ().data, -1);
			root_object = parser.get_root ().get_object ();
		}


		return root_object;
	}
		
    public Gee.List<ToodledoTask> all_tasks() {
		var l = new Gee.ArrayList<ToodledoTask> ();
		
		// pegar tarefas
		var session = new Soup.SessionAsync ();
		var url = @"http://api.toodledo.com/2/tasks/get.php?fields=folder,context,goal,location,tag,startdate,duedate,duedatemod,starttime,duetime,remind,repeat,status,star,priority,length,timer,added,note,parent,children,order;key=";
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
				var task = new ToodledoTask.from_json(geoname);
        		l.add(task);
			}
        }
		//stdout.printf("%s\n", (string) message.response_body.flatten ().data);
		return l;
	}
	
	public Toodledo(ToodledoConfig c) {
		userid = c.userid;
		password = c.password;
		appid = "jorjao81";
		apptoken = "api4dcb3e8d19a43";
		t_config = c;

		// connect to toodledo
				var url = @"http://api.toodledo.com/2/account/get.php?key=";
		var root = get_json(url);
		
		userid = root.get_string_member ("userid");
		stdout.printf("Userid: %s\n", userid);

		var alias = root.get_string_member ("alias");
		stdout.printf("alias: %s\n", alias);
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

	static int main (string[] args) 
	{
		Gtk.init (ref args);
		var app = new Main ();

		stdout.printf("Teste\n");

		if(args[1] == "--from-server") { 

			var c = new ToodledoConfig();		

			var t = new Toodledo(c);
			var l = t.all_tasks();
			foreach(var task in l) {
				task.print();
			}
		}
		else if(args[1] == "--overwrite-from-server") { 
			Database db;
			var c = new ToodledoConfig();		

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

			var t = new Toodledo(c);
			var l = t.all_tasks();
			foreach(var task in l) {
				task.print();
				task.save_to_sqlite();
			}
		}		
		else {

			var l = ToodledoTask.from_sqlite ();

			stdout.printf("Teste\n");

			foreach (var task in l) {
				task.print();
			}

		}
		return 0;
	}
}
