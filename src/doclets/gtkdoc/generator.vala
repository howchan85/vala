/* generator.vala
 *
 * Copyright (C) 2010 Luca Bruno
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Luca Bruno <lethalman88@gmail.com>
 */

using Valadoc;
using Valadoc.Api;
using Valadoc.Content;

public class Gtkdoc.Generator : Api.Visitor {
	class FileData {
		public string filename;
		public string title;
		public GComment section_comment;
		public Gee.List<GComment> comments;
		public Gee.List<string> section_lines;
		public Gee.List<string> standard_section_lines;
		public Gee.List<string> private_section_lines;

		public void register_section_line (string? line) {
			if (line != null) {
				section_lines.add (line);
			}
		}

		public void register_standard_section_line (string? line) {
			if (line != null) {
				standard_section_lines.add (line);
			}
		}

		public void register_private_section_line (string? line) {
			if (line != null) {
				private_section_lines.add (line);
			}
		}
	}

	public Gee.List<DBus.Interface> dbus_interfaces = new Gee.LinkedList<DBus.Interface>();

	private ErrorReporter reporter;
	private Settings settings;
	private Gee.Map<string, FileData> files_data = new Gee.HashMap<string, FileData>();
	private string current_cname;
	private Gee.List<Header> current_headers;
	private Api.Tree current_tree;
	private Class current_class;
	private Method current_method;
	private Delegate current_delegate;
	private Api.Signal current_signal;
	private DBus.Interface current_dbus_interface;
	private DBus.Member current_dbus_member;

	private Api.Node? current_method_or_delegate {
		get {
			if (current_method != null) {
				return current_method;
			} else if (current_delegate != null) {
				return current_delegate;
			}
			return null;
		}
	}

	public bool execute (Settings settings, Api.Tree tree, ErrorReporter reporter) {
		this.settings = settings;
		this.reporter = reporter;
		this.current_tree = tree;
		tree.accept (this);
		var code_dir = Path.build_filename (settings.path, "ccomments");
		var sections = Path.build_filename (settings.path, "%s-sections.txt".printf (settings.pkg_name));
		DirUtils.create_with_parents (code_dir, 0777);

		var sections_writer = new TextWriter (sections, "a");
		if (!sections_writer.open ()) {
			reporter.simple_error ("GtkDoc: error: unable to open %s for writing", sections_writer.filename);
			return false;
		}

		foreach (var file_data in files_data.values) {
			// C comments
			var basename = get_section (file_data.filename);
			var cwriter = new TextWriter (Path.build_filename (code_dir, "%s.c".printf (basename)), "w");

			if (!cwriter.open ()) {
				reporter.simple_error ("GtkDoc: error: unable to open %s for writing", cwriter.filename);
				return false;
			}

			// Gtkdoc SECTION
			if (file_data.section_comment != null) {
				cwriter.write_line (file_data.section_comment.to_string ());
			}

			foreach (var comment in file_data.comments) {
				cwriter.write_line (comment.to_string ());
			}
			cwriter.close ();

			// sections
			sections_writer.write_line ("<SECTION>");
			sections_writer.write_line ("<FILE>%s</FILE>".printf (basename));
			if (file_data.title != null) {
				sections_writer.write_line ("<TITLE>%s</TITLE>".printf (file_data.title));
			}

			foreach (var section_line in file_data.section_lines) {
				sections_writer.write_line (section_line);
			}

			if (file_data.standard_section_lines.size > 0) {
				sections_writer.write_line ("<SUBSECTION Standard>");

				foreach (var section_line in file_data.standard_section_lines) {
					sections_writer.write_line (section_line);
				}
			}

			if (file_data.private_section_lines.size > 0) {
				sections_writer.write_line ("<SUBSECTION Private>");

				foreach (var section_line in file_data.private_section_lines) {
					sections_writer.write_line (section_line);
				}
			}

			sections_writer.write_line ("</SECTION>");
		}
		sections_writer.close ();

		return true;
	}

	public Gee.Set<string> get_filenames () {
		return files_data.keys.read_only_view;
	}

	private FileData get_file_data (string filename) {
		var file_data = files_data[filename];
		if (file_data == null) {
			file_data = new FileData ();
			file_data.filename = filename;
			file_data.title = null;
			file_data.section_comment = null;
			file_data.comments = new Gee.LinkedList<GComment>();
			file_data.section_lines = new Gee.LinkedList<string>();
			file_data.standard_section_lines = new Gee.LinkedList<string>();
			file_data.private_section_lines = new Gee.LinkedList<string>();
			files_data[filename] = file_data;
		}
		return file_data;
	}

	private Gee.List<Header> merge_headers (Gee.List<Header> doc_headers, Gee.List<Header>? lang_headers) {
		if (lang_headers == null) {
			return doc_headers;
		}

		var headers = new Gee.LinkedList<Header>();

		foreach (var doc_header in doc_headers) {
			var header = doc_header;
			foreach (var lang_header in lang_headers) {
				if (doc_header.name == lang_header.name) {
					header.annotations = lang_header.annotations;
					if (lang_header.value != null) {
						header.value += "<para>%s</para>".printf (lang_header.value);
					}
				}
			}
			headers.add (header);
		}

		// add remaining headers
		foreach (var lang_header in lang_headers) {
			bool found = false;

			foreach (var header in headers) {
				if (header.name == lang_header.name) {
					found = true;
					break;
				}
			}

			if (!found && lang_header.value != null) {
				headers.add (lang_header);
			}
		}
		return headers;
	}

	private void set_section_comment (string filename, string section_name, Content.Comment? comment, string symbol_full_name) {
		var file_data = get_file_data (filename);
		if (file_data.title == null) {
			file_data.title = section_name;
		}
		if (comment == null) {
			return;
		}
		if (file_data.section_comment != null) {
			// already have a section comment
			return;
		}

		var gcomment = create_gcomment (get_section (filename), comment);
		gcomment.is_section = true;
		gcomment.short_description = true;
		file_data.section_comment = gcomment;

		/* gtk-doc will warn about missing long descriptions (e.g.
		 * “alias-details:Long_Description” in *-undocumented.txt), so
		 * forward that as a Valadoc warning so that it doesn’t get lost
		 * in the gtk-doc output files. */
		if (gcomment.long_comment == null || gcomment.long_comment == "") {
			reporter.simple_warning ("Missing long description in the documentation for ‘%s’ which forms gtk-doc section ‘%s’.", symbol_full_name, section_name);
		}
	}

	private GComment create_gcomment (string symbol, Content.Comment? comment, string[]? returns_annotations = null, bool is_dbus = false) {
		var converter = new Gtkdoc.CommentConverter (reporter, current_method_or_delegate);

		if (comment != null) {
			converter.convert (comment, is_dbus);
		}

		var gcomment = new GComment ();
		gcomment.symbol = symbol;
		gcomment.returns = converter.returns;
		gcomment.returns_annotations = returns_annotations;
		gcomment.see_also = converter.see_also;

		gcomment.brief_comment = converter.brief_comment;
		gcomment.long_comment = converter.long_comment;

		gcomment.headers.add_all (merge_headers (converter.parameters, current_headers));
		gcomment.versioning.add_all (converter.versioning);
		return gcomment;
	}

	private GComment add_comment (string filename, string symbol, Content.Comment? comment = null) {
		var file_data = get_file_data (filename);
		var gcomment = create_gcomment (symbol, comment);
		file_data.comments.add (gcomment);
		return gcomment;
	}

	private GComment add_symbol (string filename, string cname, Content.Comment? comment = null, string? symbol = null, string[]? returns_annotations = null) {
		var file_data = get_file_data (filename);

		file_data.register_section_line (cname);

		var gcomment = create_gcomment (symbol ?? cname, comment, returns_annotations);
		file_data.comments.add (gcomment);
		return gcomment;
	}

	private Header? add_custom_header (string name, string? comment, string[]? annotations = null, double pos = double.MAX) {
		if (comment == null && annotations == null) {
			return null;
		}

		var header = new Header (name, comment, pos);
		header.annotations = annotations;
		current_headers.add (header);
		return header;
	}

	private Header? remove_custom_header (string name) {
		var it = current_headers.iterator();
		while (it.next ()) {
			var header = it.@get ();
			if (header.name == name) {
				it.remove ();
				return header;
			}
		}
		return null;
	}

	private Header? add_header (string name, Content.Comment? comment, string[]? annotations = null, double pos = double.MAX) {
		if (comment == null && annotations == null) {
			return null;
		}

		var converter = new Gtkdoc.CommentConverter (reporter, current_method_or_delegate);
		var header = new Header (name);
		header.pos = pos;

		if (comment != null) {
			converter.convert (comment);
			if (converter.brief_comment != null) {
				header.value = converter.brief_comment;
				if (converter.long_comment != null) {
					header.value += converter.long_comment;
				}
			}
		}

		header.annotations = annotations;
		current_headers.add (header);
		return header;
	}

	public override void visit_tree (Api.Tree tree) {
		tree.accept_children (this);
	}

	public override void visit_package (Api.Package package) {
		/* we are not (yet?) interested in external packages */
		if (package.is_package) {
			return;
		}

		package.accept_all_children (this);
	}

	public override void visit_namespace (Api.Namespace ns) {
		if (ns.get_filename () != null && ns.documentation != null) {
			set_section_comment (ns.get_filename (), get_section (ns.get_filename ()), ns.documentation, ns.get_full_name ());
		}

		ns.accept_all_children (this);
	}

	public override void visit_interface (Api.Interface iface) {
		var old_cname = current_cname;
		var old_headers = current_headers;
		var old_dbus_interface = current_dbus_interface;
		current_cname = iface.get_cname ();
		current_headers = new Gee.LinkedList<Header>();
		current_dbus_interface = null;

		if (iface.get_dbus_name () != null) {
			current_dbus_interface = new DBus.Interface (settings.pkg_name, iface.get_dbus_name ());
		}

		iface.accept_all_children (this);

		var gcomment = add_symbol (iface.get_filename(), iface.get_cname(), iface.documentation, null);
		set_section_comment (iface.get_filename(), iface.get_cname(), iface.documentation, iface.get_full_name ());

		if (current_dbus_interface != null) {
			current_dbus_interface.write (settings, reporter);
			dbus_interfaces.add (current_dbus_interface);
		}

		// Handle attributes for things like deprecation.
		process_attributes (iface, gcomment);

		// Interface struct
		current_headers.clear ();

		var abstract_methods = iface.get_children_by_types ({NodeType.METHOD}, false);
		foreach (var m in abstract_methods) {
			// List all protected methods, even if they're not marked as browsable
			if (m.is_browsable (settings) || ((Symbol) m).is_protected) {
				visit_abstract_method ((Api.Method) m);
			}
		}

		var abstract_properties = iface.get_children_by_types ({NodeType.PROPERTY}, false);
		foreach (var prop in abstract_properties) {
			// List all protected properties, even if they're not marked as browsable
			if (prop.is_browsable (settings) || ((Symbol) prop).is_protected) {
				visit_abstract_property ((Api.Property) prop);
			}
		}

		add_custom_header ("parent_iface", "the parent interface structure");
		gcomment = add_symbol (iface.get_filename (), iface.get_cname () + "Iface");
		gcomment.brief_comment = "Interface for creating %s implementations.".printf (get_docbook_link (iface));

		// Standard symbols
		var file_data = get_file_data (iface.get_filename ());

		file_data.register_standard_section_line (iface.get_type_cast_macro_name ());
		file_data.register_standard_section_line (iface.get_interface_macro_name ());
		file_data.register_standard_section_line (iface.get_is_type_macro_name ());
		file_data.register_standard_section_line (iface.get_type_macro_name ());
		file_data.register_standard_section_line (iface.get_type_function_name ());

		current_cname = old_cname;
		current_headers = old_headers;
		current_dbus_interface = old_dbus_interface;
	}

	public override void visit_class (Api.Class cl) {
		var old_cname = current_cname;
		var old_headers = current_headers;
		var old_class = current_class;
		var old_dbus_interface = current_dbus_interface;
		current_cname = cl.get_cname ();
		current_headers = new Gee.LinkedList<Header>();
		current_class = cl;
		current_dbus_interface = null;

		if (cl.get_dbus_name () != null) {
			current_dbus_interface = new DBus.Interface (settings.pkg_name, cl.get_dbus_name ());
		}

		var gcomment = add_symbol (cl.get_filename(), cl.get_type_id());
		gcomment.brief_comment = "The type for %s.".printf (get_docbook_link (cl));

		cl.accept_all_children (this);

		add_symbol (cl.get_filename(), cl.get_cname(), cl.documentation, null);
		set_section_comment (cl.get_filename(), cl.get_cname(), cl.documentation, cl.get_full_name ());

		if (current_dbus_interface != null) {
			current_dbus_interface.write (settings, reporter);
			dbus_interfaces.add (current_dbus_interface);
		}

		// Handle attributes for things like deprecation.
		process_attributes (cl, gcomment);

		if (cl.is_fundamental && cl.base_type == null) {
			var filename = cl.get_filename ();

			// ref
			current_headers.clear ();
			add_custom_header ("instance", "a %s.".printf (get_docbook_link (cl)));
			gcomment = add_symbol (filename, cl.get_ref_function_cname ());
			gcomment.brief_comment = "Increases the reference count of @object.";
			gcomment.returns = "the same @object";

			// unref
			current_headers.clear ();
			add_custom_header ("instance", "a %s.".printf (get_docbook_link (cl)));
			gcomment = add_symbol (filename, cl.get_unref_function_cname ());
			gcomment.brief_comment = "Decreases the reference count of @object. When its reference count drops to 0, the object is finalized (i.e. its memory is freed).";

			// param_spec
			current_headers.clear ();
			add_custom_header ("name", "canonical name of the property specified");
			add_custom_header ("nick", "nick name for the property specified");
			add_custom_header ("blurb", "description of the property specified");
			add_custom_header ("object_type", "%s derived type of this property".printf (get_docbook_type_link (cl)));
			add_custom_header ("flags", "flags for the property specified");
			gcomment = add_symbol (filename, cl.get_param_spec_function_cname ());
			gcomment.brief_comment = "Creates a new <link linkend=\"GParamSpecBoxed\"><type>GParamSpecBoxed</type></link> instance specifying a %s derived property.".printf (get_docbook_type_link (cl));
			gcomment.long_comment = "See <link linkend=\"g-param-spec-internal\"><function>g_param_spec_internal()</function></link> for details on property names.";

			// value_set
			current_headers.clear ();
			add_custom_header ("value", "a valid <link linkend=\"GValue\"><type>GValue</type></link> of %s derived type".printf (get_docbook_type_link (cl)));
			add_custom_header ("v_object", "object value to be set");
			gcomment = add_symbol (filename, cl.get_set_value_function_cname ());
			gcomment.brief_comment = "Set the contents of a %s derived <link linkend=\"GValue\"><type>GValue</type></link> to @v_object.".printf (get_docbook_type_link (cl));
			gcomment.long_comment = "<link linkend=\"%s\"><function>%s()</function></link> increases the reference count of @v_object (the <link linkend=\"GValue\"><type>GValue</type></link> holds a reference to @v_object). If you do not wish to increase the reference count of the object (i.e. you wish to pass your current reference to the <link linkend=\"GValue\"><type>GValue</type></link> because you no longer need it), use <link linkend=\"%s\"><function>%s()</function></link> instead.

It is important that your <link linkend=\"GValue\"><type>GValue</type></link> holds a reference to @v_object (either its own, or one it has taken) to ensure that the object won't be destroyed while the <link linkend=\"GValue\"><type>GValue</type></link> still exists).".printf (to_docbook_id (cl.get_set_value_function_cname ()), cl.get_set_value_function_cname (), to_docbook_id (cl.get_take_value_function_cname ()), cl.get_take_value_function_cname ());

			// value_get
			current_headers.clear ();
			add_custom_header ("value", "a valid <link linkend=\"GValue\"><type>GValue</type></link> of %s derived type".printf (get_docbook_type_link (cl)));
			gcomment = add_symbol (filename, cl.get_get_value_function_cname ());
			gcomment.brief_comment = "Get the contents of a %s derived <link linkend=\"GValue\"><type>GValue</type></link>.".printf (get_docbook_type_link (cl));
			gcomment.returns = "object contents of @value";

			// value_take
			current_headers.clear ();
			add_custom_header ("value", "a valid <link linkend=\"GValue\"><type>GValue</type></link> of %s derived type".printf (get_docbook_type_link (cl)));
			add_custom_header ("v_object", "object value to be set");
			gcomment = add_symbol (filename, cl.get_take_value_function_cname ());
			gcomment.brief_comment = "Sets the contents of a %s derived <link linkend=\"GValue\"><type>GValue</type></link> to @v_object and takes over the ownership of the callers reference to @v_object; the caller doesn't have to unref it any more (i.e. the reference count of the object is not increased).".printf (get_docbook_type_link (cl));
			gcomment.long_comment = "If you want the GValue to hold its own reference to @v_object, use <link linkend=\"%s\"><function>%s()</function></link> instead.".printf (to_docbook_id (cl.get_set_value_function_cname ()), cl.get_set_value_function_cname ());
		}

		// Class struct
		current_headers.clear ();

		var abstract_methods = cl.get_children_by_types ({NodeType.METHOD}, false);
		foreach (var m in abstract_methods) {
			// List all protected methods, even if they're not marked as browsable
			if (m.is_browsable (settings) || ((Symbol) m).is_protected) {
				visit_abstract_method ((Api.Method) m);
			}
		}

		var abstract_properties = cl.get_children_by_types ({NodeType.PROPERTY}, false);
		foreach (var prop in abstract_properties) {
			// List all protected properties, even if they're not marked as browsable
			if (prop.is_browsable (settings) || ((Symbol) prop).is_protected) {
				visit_abstract_property ((Api.Property) prop);
			}
		}

		add_custom_header ("parent_class", "the parent class structure");
		gcomment = add_symbol (cl.get_filename (), cl.get_cname () + "Class");
		gcomment.brief_comment = "The class structure for %s. All the fields in this structure are private and should never be accessed directly.".printf (get_docbook_type_link (cl));

		// Standard/Private symbols
		var file_data = get_file_data (cl.get_filename ());

		file_data.register_standard_section_line (cl.get_is_type_macro_name ());
		file_data.register_standard_section_line (cl.get_is_class_type_macro_name ());
		file_data.register_standard_section_line (cl.get_type_cast_macro_name ());
		file_data.register_standard_section_line (cl.get_class_type_macro_name ());
		file_data.register_standard_section_line (cl.get_class_macro_name ());
		file_data.register_standard_section_line (cl.get_type_function_name ());

		file_data.register_private_section_line (cl.get_private_cname ());
		file_data.register_private_section_line (((cl.nspace.name != null)? cl.nspace.name.down () + "_" : "") + to_lower_case (cl.name) + "_construct");

		current_cname = old_cname;
		current_headers = old_headers;
		current_class = old_class;
		current_dbus_interface = old_dbus_interface;
	}

	public override void visit_struct (Api.Struct st) {
		var old_cname = current_cname;
		var old_headers = current_headers;
		current_cname = st.get_cname ();
		current_headers = new Gee.LinkedList<Header>();

		st.accept_all_children (this);
		var gcomment = add_symbol (st.get_filename(), st.get_cname(), st.documentation);

		// Handle attributes for things like deprecation.
		process_attributes (st, gcomment);

		current_cname = old_cname;
		current_headers = old_headers;

		add_symbol (st.get_filename(), st.get_dup_function_cname ());
		add_symbol (st.get_filename(), st.get_free_function_cname ());


		var file_data = get_file_data (st.get_filename ());

		file_data.register_standard_section_line (st.get_type_macro_name ());
		file_data.register_standard_section_line (st.get_type_function_name ());
	}

	/**
	 * Visit thrown error domains
	 */
	private void visit_thrown_error_domain (Api.Node error) {
		// method throws error
		Header? param_header = null;
		foreach (var header in current_headers) {
			if (header.name == "error") {
				param_header = header;
				break;
			}
		}
		var edomain = error as Api.ErrorDomain;
		if (edomain != null) {
			if (param_header == null) {
				add_custom_header ("error", "location to store the error occuring, or %NULL to ignore", {"error-domains %s".printf (edomain.get_cname ())}, double.MAX-1);
			} else {
				// assume the only annotation is error-domains
				var annotation = param_header.annotations[0];
				annotation += " %s".printf (edomain.get_cname ());
				param_header.annotations[0] = annotation;
			}
		} else if (param_header == null) {
			add_custom_header ("error", "location to store the error occuring, or %NULL to ignore", null, double.MAX-1);
		}
	}

	/**
	 * Visit error domain definitions
	 */
	public override void visit_error_domain (Api.ErrorDomain edomain) {
		// error domain definition
		var old_headers = current_headers;
		current_headers = new Gee.LinkedList<Header>();

		edomain.accept_all_children (this);
		var gcomment = add_symbol (edomain.get_filename(), edomain.get_cname(), edomain.documentation);

		// Handle attributes for things like deprecation.
		process_attributes (edomain, gcomment);

		// Standard symbols
		var file_data = get_file_data (edomain.get_filename ());

		file_data.register_standard_section_line (edomain.get_quark_function_name ());
		file_data.register_standard_section_line (edomain.get_quark_macro_name ());

		current_headers = old_headers;
	}

	public override void visit_error_code (Api.ErrorCode ecode) {
		add_header (ecode.get_cname (), ecode.documentation);
		ecode.accept_all_children (this);
	}

	public override void visit_enum (Api.Enum en) {
		var old_headers = current_headers;
		current_headers = new Gee.LinkedList<Header>();

		en.accept_all_children (this);
		var gcomment = add_symbol (en.get_filename(), en.get_cname(), en.documentation);
	
		// Handle attributes for things like deprecation.
		process_attributes (en, gcomment);

		// Standard symbols
		var file_data = get_file_data (en.get_filename ());

		file_data.register_standard_section_line (en.get_type_macro_name ());
		file_data.register_standard_section_line (en.get_type_function_name ());

		current_headers = old_headers;
	}

	public override void visit_enum_value (Api.EnumValue eval) {
		add_header (eval.get_cname (), eval.documentation);
		eval.accept_all_children (this);
	}

	private string combine_comments (string? brief, string? @long) {
		StringBuilder builder = new StringBuilder ();
		if (brief != null) {
			builder.append (brief.strip ());
		}

		string _long = (@long != null)? @long.strip () : "";
		if (builder.len > 0 && _long != "") {
			builder.append ("\n\n");
		}

		if (_long != "") {
			builder.append (_long);
		}

		return (owned) builder.str;
	}

	public override void visit_property (Api.Property prop) {
		if (prop.is_override || prop.is_private || (!prop.is_abstract && !prop.is_virtual && prop.base_property != null)) {
			return;
		}

		var gcomment = add_comment (prop.get_filename(), "%s:%s".printf (current_cname, prop.get_cname ()), prop.documentation);
		prop.accept_all_children (this);

		// Handle attributes for things like deprecation.
		process_attributes (prop, gcomment);

		if (prop.getter != null && !prop.getter.is_private && prop.getter.is_get) {
			var getter_gcomment = add_symbol (prop.get_filename(), prop.getter.get_cname ());
			getter_gcomment.headers.add (new Header ("self", "the %s instance to query".printf (get_docbook_link (prop.parent)), 1));
			getter_gcomment.returns = "the value of the %s property".printf (get_docbook_link (prop));
			getter_gcomment.brief_comment = "Get and return the current value of the %s property.".printf (get_docbook_link (prop));
			getter_gcomment.long_comment = combine_comments (gcomment.brief_comment, gcomment.long_comment);

			if (prop.property_type != null && prop.property_type.data_type is Api.Array) {
				var array_type = prop.property_type.data_type;
				for (uint dim = 1; array_type != null && array_type is Api.Array; dim++, array_type = ((Api.Array) array_type).data_type) {
					gcomment.headers.add (new Header ("result_length%u".printf (dim), "return location for the length of the property's value"));
				}
			}

			/* Copy versioning headers such as deprecation and since lines. */
			getter_gcomment.versioning = gcomment.versioning;
		}

		if (prop.setter != null && !prop.setter.is_private && prop.setter.is_set) {
			var setter_gcomment = add_symbol (prop.get_filename(), prop.setter.get_cname ());
			setter_gcomment.headers.add (new Header ("self", "the %s instance to modify".printf (get_docbook_link (prop.parent)), 1));
			setter_gcomment.headers.add (new Header ("value", "the new value of the %s property".printf (get_docbook_link (prop)), 2));
			setter_gcomment.brief_comment = "Set the value of the %s property to @value.".printf (get_docbook_link (prop));
			setter_gcomment.long_comment = combine_comments (gcomment.brief_comment, gcomment.long_comment);

			if (prop.property_type != null && prop.property_type.data_type is Api.Array) {
				var array_type = prop.property_type.data_type;
				for (uint dim = 1; array_type != null && array_type is Api.Array; dim++, array_type = ((Api.Array) array_type).data_type) {
					gcomment.headers.add (new Header ("value_length%u".printf (dim), "length of the property's new value"));
				}
			}

			/* Copy versioning headers such as deprecation and since lines. */
			setter_gcomment.versioning = gcomment.versioning;
		}
	}

	public override void visit_field (Api.Field f) {
		if (f.is_private) {
			return;
		}

		if (current_headers == null) {
			// field not in class/struct/interface
			var gcomment = add_symbol (f.get_filename(), f.get_cname(), f.documentation);
			f.accept_all_children (this);
	
			// Handle attributes for things like deprecation.
			process_attributes (f, gcomment);
		} else {
			add_header (f.get_cname (), f.documentation);
			f.accept_all_children (this);
		}
	}

	public override void visit_constant (Api.Constant c) {
		var gcomment = add_symbol (c.get_filename(), c.get_cname(), c.documentation);
		c.accept_all_children (this);

		// Handle attributes for things like deprecation.
		process_attributes (c, gcomment);
	}

	public override void visit_delegate (Api.Delegate d) {
		var old_headers = current_headers;
		var old_delegate = current_delegate;
		current_headers = new Gee.LinkedList<Header>();
		current_delegate = d;

		d.accept_children ({NodeType.FORMAL_PARAMETER, NodeType.TYPE_PARAMETER}, this);
		var exceptions = d.get_children_by_types ({NodeType.ERROR_DOMAIN, NodeType.CLASS});
		foreach (var ex in exceptions) {
			visit_thrown_error_domain (ex);
		}

		if (!d.is_static) {
			add_custom_header ("user_data", "data to pass to the delegate function", {"closure"});
		}

		var gcomment = add_symbol (d.get_filename(), d.get_cname(), d.documentation);
	
		// Handle attributes for things like deprecation.
		process_attributes (d, gcomment);

		current_headers = old_headers;
		current_delegate = old_delegate;
	}

	public override void visit_signal (Api.Signal sig) {
		var old_headers = current_headers;
		var old_signal = current_signal;
		var old_dbus_member = current_dbus_member;
		current_headers = new Gee.LinkedList<Header>();
		current_signal = sig;
		current_dbus_member = null;

		if (current_dbus_interface != null && sig.is_dbus_visible) {
			current_dbus_member = new DBus.Member (sig.get_dbus_name ());
		}

		sig.accept_all_children (this);

		var name = sig.get_cname().replace ("_", "-");
		var gcomment = add_comment (sig.get_filename(), "%s::%s".printf (current_cname, name), sig.documentation);
		// gtkdoc maps parameters by their ordering, so let's customly add the first parameter
		gcomment.headers.insert (0, new Header (to_lower_case (((Api.Node)sig.parent).name),
												   "the %s instance that received the signal".printf (get_docbook_link (sig.parent)), 0.1));
		if (current_dbus_interface != null && sig.is_dbus_visible) {
			var dbuscomment = create_gcomment (sig.get_dbus_name (), sig.documentation, null, true);
			current_dbus_member.comment = dbuscomment;
			current_dbus_interface.add_signal (current_dbus_member);
		}

		// Handle attributes for things like deprecation.
		process_attributes (sig, gcomment);

		current_headers = old_headers;
		current_signal = old_signal;
		current_dbus_member = old_dbus_member;
	}

	public override void visit_method (Api.Method m) {
		if ((m.is_constructor && current_class != null && current_class.is_abstract) || m.is_override || m.is_private || (!m.is_abstract && !m.is_virtual && m.base_method != null)) {
			return;
		}

		var annotations = new string[]{};

		if (m.return_type != null) {
			if (m.return_type.data_type is Api.Array) {
				annotations += "array length=result_length1";
			}

			if (m.return_type.is_unowned) {
				annotations += "transfer none";
			}
		}

		var old_headers = current_headers;
		var old_method = current_method;
		var old_dbus_member = current_dbus_member;
		current_headers = new Gee.LinkedList<Header>();
		current_method = m;
		current_dbus_member = null;

		if (current_dbus_interface != null && m.is_dbus_visible && !m.is_constructor) {
			current_dbus_member = new DBus.Member (m.get_dbus_name ());
		}

		if (!m.is_static && !m.is_constructor) {
			add_custom_header ("self", "the %s instance".printf (get_docbook_link (m.parent)), null, 0.1);
		}

		m.accept_children ({NodeType.FORMAL_PARAMETER, NodeType.TYPE_PARAMETER}, this);
		var exceptions = m.get_children_by_types ({NodeType.ERROR_DOMAIN, NodeType.CLASS});
		foreach (var ex in exceptions) {
			visit_thrown_error_domain (ex);
		}

		Header error_header = null;
		GComment gcomment = null;
		if (m.is_yields) {
			add_custom_header ("_callback_", "callback to call when the request is satisfied", {"scope async"});
			add_custom_header ("_user_data_", "the data to pass to @_callback_ function", {"closure"});
			// remove error from here, put that in the _finish function
			error_header = remove_custom_header ("error");

			gcomment = add_symbol (m.get_filename(), m.get_cname (), m.documentation);
			gcomment.returns = null; // async method has no return value
			var see_also = gcomment.see_also; // vala bug
			see_also += get_docbook_link (m, false, true);
			gcomment.see_also = see_also;
		} else {
			gcomment = add_symbol (m.get_filename(), m.get_cname (), m.documentation, null, annotations);
		}

		// Handle attributes for things like deprecation.
		process_attributes (m, gcomment);

		remove_custom_header ("self");

		if (current_dbus_interface != null && m.is_dbus_visible && !m.is_constructor) {
			if (m.return_type != null && m.return_type.data_type != null) {
				var dresult = new DBus.Parameter (m.get_dbus_result_name (), m.return_type.get_dbus_type_signature (), DBus.Parameter.Direction.OUT);
				current_dbus_member.add_parameter (dresult);
			}
			var dbus_gcomment = create_gcomment (m.get_dbus_name (), m.documentation, null, true);
			current_dbus_member.comment = dbus_gcomment;
			current_dbus_interface.add_method (current_dbus_member);
		}

		current_headers = old_headers;
		current_method = old_method;
		current_dbus_member = old_dbus_member;

		if (m.is_yields) {
			var finish_gcomment = add_symbol (m.get_filename(), m.get_finish_function_cname (), m.documentation);
			finish_gcomment.headers.clear ();

			if (!m.is_static) {
				finish_gcomment.headers.add (new Header ("self", "the %s instance".printf (get_docbook_link (m.parent))));
			}
			finish_gcomment.headers.add (new Header ("_res_", "a <link linkend=\"GAsyncResult\"><type>GAsyncResult</type></link>"));
			if (error_header != null) {
				finish_gcomment.headers.add (error_header);
			}

			var see_also = finish_gcomment.see_also; // vala bug
			see_also += get_docbook_link (m);
			finish_gcomment.see_also = see_also;
		}

		if (m.is_constructor && !m.get_cname ().has_suffix ("_new")) {
			// Hide secondary _construct methods from the documentation (the primary _construct method is hidden in visit_class())
			var file_data = get_file_data (m.get_filename ());
			file_data.private_section_lines.add (m.get_cname ().replace ("_new", "_construct"));
		}
	}

	/**
	 * Visit abstract methods
	 */
	private void visit_abstract_method (Api.Method m) {
		if (!m.is_abstract && !m.is_virtual) {
			return;
		}

		if (!m.is_private && !m.is_protected && !m.is_internal) {
			add_custom_header (m.name, "virtual method called by %s".printf (get_docbook_link (m)));

			if (m.is_yields) {
				add_custom_header (m.name + "_finish", "asynchronous finish function for <structfield>%s</structfield>, called by %s".printf (m.name, get_docbook_link (m)));
			}
		} else {
			add_custom_header (m.name, "virtual method used internally");

			if (m.is_yields) {
				add_custom_header (m.name + "_finish", "asynchronous finish function used internally");
			}
		}
	}

	/**
	 * Visit abstract properties
	 */
	private void visit_abstract_property (Api.Property prop) {
		if (!prop.is_abstract && !prop.is_virtual) {
			return;
		}

		if (prop.getter != null && !prop.getter.is_private && !prop.getter.is_internal && prop.getter.is_get) {
			add_custom_header ("get_" + prop.name, "getter method for the abstract property %s".printf (get_docbook_link (prop)));
		}

		if (prop.setter != null && !prop.setter.is_private && !prop.setter.is_internal && prop.setter.is_set && !prop.setter.is_construct) {
			add_custom_header ("set_" + prop.name, "setter method for the abstract property %s".printf (get_docbook_link (prop)));
		}
	}

	public override void visit_formal_parameter (Api.FormalParameter param) {
		var param_name = param.name ?? "...";
		var annotations = new string[]{};
		var direction = "in";

		if (param.is_out) {
			direction = "out";
		} else if (param.is_ref) {
			direction = "inout";
		}
		annotations += direction;

		if (param.parameter_type.is_nullable) {
			annotations += "allow-none";
		}

		if (param.parameter_type.is_owned && !(param.parameter_type.data_type is Api.Delegate)) {
			annotations += "transfer full";
		}

		if (param.parameter_type.data_type is Api.Array) {
			annotations += "array length=%s_length1".printf (param_name);
			add_custom_header ("%s_length1".printf (param_name), "length of the @%s array".printf (param_name),
				null, get_parameter_pos (current_method_or_delegate, param_name)+0.1);
		}

		if (!param.ellipsis && param.parameter_type.data_type != null && get_cname (param.parameter_type.data_type) == "GError") {
			annotations += "not-error";
		}

		if (current_signal != null && param.documentation == null) {
			// gtkdoc writes arg0, arg1 which is ugly. As a workaround, we always add an header for them.
			add_custom_header (param_name, "", null);
		} else {
			add_header (param_name, param.documentation, annotations,
				get_parameter_pos (current_method_or_delegate, param_name));
		}

		if (param.parameter_type.data_type is Api.Delegate) {
			add_custom_header ("%s_target".printf (param_name), "user data to pass to @%s".printf (param_name),
				{"allow-none", "closure"}, get_parameter_pos (current_method_or_delegate, param_name)+0.1);
			if (param.parameter_type.is_owned) {
				add_custom_header ("%s_target_destroy_notify".printf (param_name),
								   "function to call when @%s_target is no longer needed".printf (param_name), {"allow-none"},
								   get_parameter_pos (current_method_or_delegate, param_name)+0.2);
			}
		}

		if (current_dbus_member != null) {
			var ddirection = DBus.Parameter.Direction.IN;
			if (current_signal != null) {
				ddirection = DBus.Parameter.Direction.NONE;
			} else if (param.is_out) {
				ddirection = DBus.Parameter.Direction.OUT;
			}
			var dparam = new DBus.Parameter (param_name, param.parameter_type.get_dbus_type_signature (), ddirection);
			current_dbus_member.add_parameter (dparam);
		}
		param.accept_all_children (this);
	}

	private void process_attributes (Symbol sym, GComment gcomment) {
		// Handle the ‘Deprecated’ attribute.
		var deprecated_attribute = sym.get_attribute ("Deprecated");

		if (deprecated_attribute != null) {
			var _since = deprecated_attribute.get_argument ("since");
			string? since = null;
			if (_since != null) {
				since = _since.value;

				// Strip surrounding quotation marks.
				if (since.has_prefix ("\"")) {
					since = since[1:since.length - 1];
				}
				if (since.has_suffix ("\"")) {
					since = since[0:-1];
				}
			}

			var replacement = deprecated_attribute.get_argument ("replacement");
			string? replacement_symbol_name = null;
			Api.Node? replacement_symbol = null;

			if (replacement != null) {
				replacement_symbol_name = replacement.value;

				// Strip surrounding quotation marks.
				if (replacement_symbol_name.has_prefix ("\"")) {
					replacement_symbol_name = replacement_symbol_name[1:replacement_symbol_name.length - 1];
				}
				if (replacement_symbol_name.has_suffix ("\"")) {
					replacement_symbol_name = replacement_symbol_name[0:-1];
				}

				// Strip any trailing brackets.
				if (replacement_symbol_name.has_suffix ("()")) {
					replacement_symbol_name = replacement_symbol_name[0:-2];
				}

				replacement_symbol = current_tree.search_symbol_str (sym, replacement_symbol_name);
			}

			if (replacement != null && replacement_symbol == null) {
				reporter.simple_warning ("Couldn’t resolve replacement symbol ‘%s’ for ‘Deprecated’ attribute on %s.", replacement_symbol_name, sym.get_full_name ());
			}

			var deprecation_string = "No replacement specified.";

			if (since != null && replacement_symbol != null) {
				deprecation_string = "%s: Replaced by %s.".printf (since, get_gtkdoc_link (replacement_symbol));
			} else if (since != null && replacement_symbol == null) {
				deprecation_string = "%s: No replacement specified.".printf (since);
			} else if (since == null && replacement_symbol != null) {
				deprecation_string = "Replaced by %s.".printf (get_gtkdoc_link (replacement_symbol));
			} else {
				reporter.simple_warning ("Missing ‘since’ and ‘replacement’ arguments to ‘Deprecated’ attribute on %s.", sym.get_full_name ());
			}

			gcomment.versioning.add (new Header ("Deprecated", deprecation_string));
		}
	}
}
