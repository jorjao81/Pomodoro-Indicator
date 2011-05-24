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

public class ToodledoTask : GLib.Object
{
	public string title { get; set; default = ""; } // TODO encode the & character as %26 and the ; character as %3B
	public string tag { get; set; default = "";} // TODO ncode the & character as %26 and the ; character as %3B.
	public int folder { get; set; default = 0; }
	public int context { get; set; default = 0; }
	public int goal { get; set; default = 0; }
	public int location { get; set; default = 0; }
	public int parent { get; set; default = 0; }
	public int children { get; set; default = 0; }
	//public int order { get; set; }
	public int duedate {get; set; default = 0; }
	public int duedatemod {get; set; default = 0; }
	public int duetime {get; set; default = 0; }
	public int startdate {get; set; default = 0; }
	public int starttime {get; set; default = 0; }
	public int remind {get; set; default = 0; }
	public string repeat {get; set; default = ""; }
	public int repeatfrom {get; set; default = 0; }
	public int status {get; set; default = 0; }
	public int length {get; set; default = 0; }
	public int priority {get; set; default = 1; }
	public int star {get; set; default = 0; }
	public int modified {get; set; default = 0; }	
	public int completed {get; set; default = 0; }	
	public int added {get; set; default = 0; }	
	public int timer {get; set; default = 0; }	
	public string note {get; set; default = ""; }

	public ToodledoTask() {
	}

	public ToodledoTask.from_json(Json.Object task) {
		if(task.has_member("title")) {
			this.title = task.get_string_member("title");
		}
	}

}	
		

public class Toodledo : GLib.Object
{
	private string userid;
	private string password;
	private string appid;	
    private string apptoken;
	private string key;

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

		key = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, temp, temp.length);
		return key;
	}
		

	private Json.Object get_json(string url) {
		// try to connect with old key
		var session = new Soup.SessionAsync ();

		var message = new Soup.Message("GET", url + key);
		session.send_message (message);
		   var parser = new Json.Parser ();
		parser.load_from_data ((string) message.response_body.flatten ().data, -1);
		var root_object = parser.get_root ().get_object ();

		int error;
		if ((error = (int)root_object.get_int_member ("errorCode")) == 2) {
			stdout.printf("Error %i\n", error);
			key = get_key();
			message = new Soup.Message("GET", url + key);
			session.send_message (message);
		   	parser.load_from_data ((string) message.response_body.flatten ().data, -1);
			root_object = parser.get_root ().get_object ();
		}


		return root_object;
	}
		
    public void print_all_tasks() {
		// pegar tarefas
		var session = new Soup.SessionAsync ();
		var url = @"http://api.toodledo.com/2/tasks/get.php?fields=folder,star,priority;key=";
			var message = new Soup.Message("GET", url + key);
			session.send_message (message);
  			var parser = new Json.Parser ();
		   	parser.load_from_data ("{\"tarefas\" : " + (string) message.response_body.flatten ().data + "}", -1);
			var troot_object = parser.get_root ().get_object ();
		
		foreach (var node in troot_object.get_array_member("tarefas").get_elements ()) {
			var geoname = node.get_object ();
			var task = new ToodledoTask.from_json(geoname);
            stdout.printf ("%s\n\n", task.title);
        }
	}
	
	public Toodledo(string _userid, string _password) {
		userid = _userid;
		password = _password;
		appid = "jorjao81";
		apptoken = "api4dcb3e8d19a43";
		key = "bla";

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

		var userid = "td4dc848c2b588e";
		var password = "Agatha84";
		var t = new Toodledo(userid, password);
		t.print_all_tasks();

		stdout.printf("Bla\n");
		return 0;
	}
}
