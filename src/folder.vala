/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* toodledo
 *
 * Copyright (C) Paulo Schreiner 2011 <paulo@netbook>
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


 class ToodledoFolder : GLib.Object
{
	public string name { get; set; default = ""; }
	public int id { get; set; default = 0; }
	public int archived { get; set; default = 0; }
	public int ord { get; set; default = 0; }
	public int private { get; set; default = 0; }

	/* we want to store all folders in memory indexed by id */
	public static Gee.HashMap<int, ToodledoFolder> mapa = new Gee.HashMap<int, ToodledoFolder>();

	private static string database {get; set; default = "/home/paulo/.toodledo/toodledo.sqlite"; } 

	public ToodledoConfig config {get; set; }

	public ToodledoFolder.from_array(string[] arr) {
		
	}

	public void print () {
		stdout.printf(@"$(id): $(name)\n");
	}
		 
	
	public ToodledoFolder.from_json(Json.Object task) {
		_name = task.get_string_member("name");
		_private = json_get_integer(task, "private");
		_archived = json_get_integer(task, "archived");
		_ord = json_get_integer(task, "ord");
		_id = json_get_integer(task, "id");


		mapa.set(id, this);	}

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
		rc = db.exec(@"DELETE FROM TASKS WHERE id = $id; INSERT INTO tasks VALUES ($(_id), \"$(_name)\", $(_private), $(_archived), $(_ord)");
		if (rc != Sqlite.OK) { 
            stderr.printf ("SQL error: %d, %s\n", rc, db.errmsg ());
            return false;
        }


		return true;

	}
		

}
