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

		var appid = "jorjao81";
		var token = "api4dcb3e8d19a43";
	
		var userid = "td4dc848c2b588e";
		size_t size = (userid + token).length;
		var md5 =GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, userid 
		                                       + token, size); 

		stdout.printf(@"$md5 \n");

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
		token2 = "td4dd3384157477";

		stdout.printf("%s\n", token2);

		var temp = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, user_pw, user_pw.length)
		                        + token + token2;

		var chave = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, temp, temp.length);
		
		stdout.printf("%s\n",chave);

		url = @"http://api.toodledo.com/2/account/get.php?key=$chave";
		message = new Soup.Message("GET", url);
		session.send_message (message);

		stdout.write (message.response_body.data);
	    stdout.printf("\n");

		// pegar tarefas
		url = @"http://api.toodledo.com/2/tasks/get.php?key=$chave;fields=folder,star,priority";
		message = new Soup.Message("GET", url);
		session.send_message (message);

		stdout.write (message.response_body.data);
	    stdout.printf("\n");

		return 0;
	}
}