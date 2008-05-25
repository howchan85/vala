/* valainterfacewriter.vala
 *
 * Copyright (C) 2006-2008  Jürg Billeter, Raffaele Sandrini
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 */

using GLib;
using Gee;

/**
 * Code visitor generating Vala API file for the public interface.
 */
public class Vala.InterfaceWriter : CodeVisitor {
	private CodeContext context;
	
	FileStream stream;
	
	int indent;
	/* at begin of line */
	bool bol = true;

	string current_cheader_filename;

	Scope current_scope;

	/**
	 * Writes the public interface of the specified code context into the
	 * specified file.
	 *
	 * @param context  a code context
	 * @param filename a relative or absolute filename
	 */
	public void write_file (CodeContext context, string filename) {
		this.context = context;
	
		stream = FileStream.open (filename, "w");

		write_string ("/* %s generated by %s, do not modify. */".printf (Path.get_basename (filename), Environment.get_prgname ()));
		write_newline ();
		write_newline ();

		current_scope = context.root.scope;

		context.accept (this);

		current_scope = null;

		stream = null;
	}

	public override void visit_namespace (Namespace ns) {
		if (ns.external_package) {
			return;
		}

		if (ns.name == null)  {
			ns.accept_children (this);
			return;
		}

		write_indent ();
		write_string ("[CCode (cprefix = \"%s\", lower_case_cprefix = \"%s\")]".printf (ns.get_cprefix (), ns.get_lower_case_cprefix ()));
		write_newline ();

		write_indent ();
		write_string ("namespace ");
		write_identifier (ns.name);
		write_begin_block ();

		current_scope = ns.scope;
		ns.accept_children (this);
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_class (Class cl) {
		if (cl.external_package) {
			return;
		}

		if (!check_accessibility (cl)) {
			return;
		}

		if (cl.is_compact) {
			write_indent ();
			write_string ("[Compact]");
			write_newline ();
		}

		write_indent ();
		
		write_string ("[CCode (");

		if (cl.is_reference_counting ()) {
			if (cl.base_class == null || cl.base_class.get_ref_function () == null || cl.base_class.get_ref_function () != cl.get_ref_function ()) {
				write_string ("ref_function = \"%s\", ".printf (cl.get_ref_function ()));
			}
			if (cl.base_class == null || cl.base_class.get_unref_function () == null || cl.base_class.get_unref_function () != cl.get_unref_function ()) {
				write_string ("unref_function = \"%s\", ".printf (cl.get_unref_function ()));
			}
		} else {
			if (cl.get_dup_function () != null) {
				write_string ("copy_function = \"%s\", ".printf (cl.get_dup_function ()));
			}
			if (cl.get_free_function () != cl.get_default_free_function ()) {
				write_string ("free_function = \"%s\", ".printf (cl.get_free_function ()));
			}
		}

		if (cl.get_cname () != cl.get_default_cname ()) {
			write_string ("cname = \"%s\", ".printf (cl.get_cname ()));
		}

		bool first = true;
		string cheaders;
		foreach (string cheader in cl.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}
		write_string ("cheader_filename = \"%s\")]".printf (cheaders));
		write_newline ();
		
		write_indent ();
		write_accessibility (cl);
		if (cl.is_static) {
			write_string ("static ");
		} else if (cl.is_abstract) {
			write_string ("abstract ");
		}
		write_string ("class ");
		write_identifier (cl.name);

		var type_params = cl.get_type_parameters ();
		if (type_params.size > 0) {
			write_string ("<");
			bool first = true;
			foreach (TypeParameter type_param in type_params) {
				if (first) {
					first = false;
				} else {
					write_string (",");
				}
				write_identifier (type_param.name);
			}
			write_string (">");
		}

		var base_types = cl.get_base_types ();
		if (base_types.size > 0) {
			write_string (" : ");
		
			bool first = true;
			foreach (DataType base_type in base_types) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}
				write_type (base_type);
			}
		}
		write_begin_block ();

		current_scope = cl.scope;
		cl.accept_children (this);
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_struct (Struct st) {
		if (st.external_package) {
			return;
		}

		if (!check_accessibility (st)) {
			return;
		}
		
		write_indent ();

		write_string ("[CCode (");

		if (st.get_cname () != st.get_default_cname ()) {
			write_string ("cname = \"%s\", ".printf (st.get_cname ()));
		}

		var first = true;
		string cheaders;
		foreach (string cheader in st.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}
		write_string ("cheader_filename = \"%s\")]".printf (cheaders));
		write_newline ();

		if (st.is_simple_type ()) {
			write_indent ();
			write_string ("[SimpleType]");
			write_newline ();
		}

		write_indent ();
		write_accessibility (st);
		write_string ("struct ");
		write_identifier (st.name);

		var base_types = st.get_base_types ();
		if (base_types.size > 0) {
			write_string (" : ");
		
			bool first = true;
			foreach (DataType base_type in base_types) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}
				write_type (base_type);
			}
		}

		write_begin_block ();

		current_scope = st.scope;
		st.accept_children (this);
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_interface (Interface iface) {
		if (iface.external_package) {
			return;
		}

		if (!check_accessibility (iface)) {
			return;
		}

		write_indent ();

		var first = true;
		string cheaders;
		foreach (string cheader in iface.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}
		write_string ("[CCode (cheader_filename = \"%s\"".printf (cheaders));
		if (iface.get_lower_case_csuffix () != iface.get_default_lower_case_csuffix ())
			write_string (", lower_case_csuffix = \"%s\"".printf (iface.get_lower_case_csuffix ()));

		write_string (")]");
		write_newline ();

		write_indent ();
		write_accessibility (iface);
		write_string ("interface ");
		write_identifier (iface.name);

		var type_params = iface.get_type_parameters ();
		if (type_params.size > 0) {
			write_string ("<");
			bool first = true;
			foreach (TypeParameter type_param in type_params) {
				if (first) {
					first = false;
				} else {
					write_string (",");
				}
				write_identifier (type_param.name);
			}
			write_string (">");
		}

		var prerequisites = iface.get_prerequisites ();
		if (prerequisites.size > 0) {
			write_string (" : ");
		
			bool first = true;
			foreach (DataType prerequisite in prerequisites) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}
				write_type (prerequisite);
			}
		}
		write_begin_block ();

		current_scope = iface.scope;
		iface.accept_children (this);
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_enum (Enum en) {
		if (en.external_package) {
			return;
		}

		if (!check_accessibility (en)) {
			return;
		}

		write_indent ();

		bool first = true;
		string cheaders;
		foreach (string cheader in en.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}

		write_string ("[CCode (cprefix = \"%s\", ".printf (en.get_cprefix ()));

		if (!en.has_type_id) {
			write_string ("has_type_id = \"%d\", ".printf (en.has_type_id));
		}

		write_string ("cheader_filename = \"%s\")]".printf (cheaders));

		if (en.is_flags) {
			write_indent ();
			write_string ("[Flags]");
		}

		write_indent ();
		write_accessibility (en);
		write_string ("enum ");
		write_identifier (en.name);
		write_begin_block ();

		first = true;
		foreach (EnumValue ev in en.get_values ()) {
			if (first) {
				first = false;
			} else {
				write_string (",");
				write_newline ();
			}

			write_indent ();
			write_identifier (ev.name);
		}

		if (!first) {
			if (en.get_methods ().size > 0) {
				write_string (";");
			}
			write_newline ();
		}

		current_scope = en.scope;
		foreach (Method m in en.get_methods ()) {
			m.accept (this);
		}
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_error_domain (ErrorDomain edomain) {
		if (edomain.external_package) {
			return;
		}

		if (!check_accessibility (edomain)) {
			return;
		}

		write_indent ();

		var first = true;
		string cheaders;
		foreach (string cheader in edomain.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}
		write_string ("[CCode (cprefix = \"%s\", cheader_filename = \"%s\")]".printf (edomain.get_cprefix (), cheaders));

		write_indent ();
		write_accessibility (edomain);
		write_string ("errordomain ");
		write_identifier (edomain.name);
		write_begin_block ();

		edomain.accept_children (this);

		write_end_block ();
		write_newline ();
	}

	public override void visit_error_code (ErrorCode ecode) {
		write_indent ();
		write_identifier (ecode.name);
		write_string (",");
		write_newline ();
	}

	public override void visit_constant (Constant c) {
		if (c.external_package) {
			return;
		}

		if (!check_accessibility (c)) {
			return;
		}

		if (c.get_cname () != c.get_default_cname ()) {
			write_indent ();
			write_string ("[CCode (cname = \"%s\")]".printf (c.get_cname ()));
		}

		write_indent ();
		write_accessibility (c);
		write_string ("const ");

		write_type (c.type_reference);
			
		write_string (" ");
		write_identifier (c.name);
		write_string (";");
		write_newline ();
	}

	public override void visit_field (Field f) {
		if (f.external_package) {
			return;
		}

		if (!check_accessibility (f)) {
			return;
		}

		if (f.get_cname () != f.get_default_cname ()) {
			write_indent ();
			write_string ("[CCode (cname = \"%s\")]".printf (f.get_cname ()));
		}

		if (f.no_array_length && f.field_type is ArrayType) {
			write_indent ();
			write_string ("[NoArrayLength]");
		}

		write_indent ();
		write_accessibility (f);

		if (is_weak (f.field_type)) {
			write_string ("weak ");
		}

		write_type (f.field_type);
			
		write_string (" ");
		write_identifier (f.name);
		write_string (";");
		write_newline ();
	}
	
	private void write_error_domains (Collection<DataType> error_domains) {
		if (error_domains.size > 0) {
			write_string (" throws ");

			bool first = true;
			foreach (DataType type in error_domains) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}

				write_type (type);
			}
		}
	}

	// equality comparison with 3 digit precision
	private bool float_equal (double d1, double d2) {
		return ((int) (d1 * 1000)) == ((int) (d2 * 1000));
	}

	private void write_params (Collection<FormalParameter> params) {
		write_string ("(");

		int i = 1;
		foreach (FormalParameter param in params) {
			if (i > 1) {
				write_string (", ");
			}
			
			if (param.ellipsis) {
				write_string ("...");
				continue;
			}
			

			var ccode_params = new StringBuilder ();
			var separator = "";

			if (!float_equal (param.carray_length_parameter_position, i + 0.1)) {
				ccode_params.append_printf ("%sarray_length_pos = %g", separator, param.carray_length_parameter_position);
				separator = ", ";
			}
			if (!float_equal (param.cdelegate_target_parameter_position, i + 0.1)) {
				ccode_params.append_printf ("%sdelegate_target_pos = %g", separator, param.cdelegate_target_parameter_position);
				separator = ", ";
			}

			if (ccode_params.len > 0) {
				write_string ("[CCode (%s)] ".printf (ccode_params.str));
			}

			if (param.direction != ParameterDirection.IN) {
				if (param.direction == ParameterDirection.REF) {
					write_string ("ref ");
				} else if (param.direction == ParameterDirection.OUT) {
					write_string ("out ");
				}
				if (is_weak (param.parameter_type)) {
					write_string ("weak ");
				}
			}

			write_type (param.parameter_type);

			if (param.direction == ParameterDirection.IN && param.parameter_type.value_owned) {
				write_string ("#");
			}

			write_string (" ");
			write_identifier (param.name);
			
			if (param.default_expression != null) {
				write_string (" = ");
				write_string (param.default_expression.to_string ());
			}

			i++;
		}

		write_string (")");
	}

	public override void visit_delegate (Delegate cb) {
		if (cb.external_package) {
			return;
		}

		if (!check_accessibility (cb)) {
			return;
		}

		write_indent ();

		var first = true;
		string cheaders;
		foreach (string cheader in cb.get_cheader_filenames ()) {
			if (first) {
				cheaders = cheader;
				first = false;
			} else {
				cheaders = "%s,%s".printf (cheaders, cheader);
			}
		}
		write_string ("[CCode (cheader_filename = \"%s\")]".printf (cheaders));

		write_indent ();

		write_accessibility (cb);
		if (!cb.has_target) {
			write_string ("static ");
		}
		write_string ("delegate ");
		
		write_return_type (cb.return_type);
		
		write_string (" ");
		write_identifier (cb.name);
		
		write_string (" ");
		
		write_params (cb.get_parameters ());

		write_string (";");

		write_newline ();
	}

	public override void visit_method (Method m) {
		if (m.external_package) {
			return;
		}

		// don't write interface implementation unless it's an abstract or virtual method
		if (!check_accessibility (m) || m.overrides || (m.base_interface_method != null && !m.is_abstract && !m.is_virtual)) {
			return;
		}

		if (m.get_attribute ("NoWrapper") != null) {
			write_indent ();
			write_string ("[NoWrapper]");
		}
		if (m.no_array_length) {
			bool array_found = (m.return_type is ArrayType);
			foreach (FormalParameter param in m.get_parameters ()) {
				if (param.parameter_type is ArrayType) {
					array_found = true;
					break;
				}
			}
			if (array_found) {
				write_indent ();
				write_string ("[NoArrayLength]");
			}
		}

		var ccode_params = new StringBuilder ();
		var separator = "";

		if (m.get_cname () != m.get_default_cname ()) {
			ccode_params.append_printf ("%scname = \"%s\"", separator, m.get_cname ());
			separator = ", ";
		}
		if (m.parent_symbol is Namespace) {
			bool first = true;
			string cheaders;
			foreach (string cheader in m.get_cheader_filenames ()) {
				if (first) {
					cheaders = cheader;
					first = false;
				} else {
					cheaders = "%s,%s".printf (cheaders, cheader);
				}
			}
			ccode_params.append_printf ("%scheader_filename = \"%s\"", separator, cheaders);
			separator = ", ";
		}
		if (!float_equal (m.cinstance_parameter_position, 0)) {
			ccode_params.append_printf ("%sinstance_pos = %g", separator, m.cinstance_parameter_position);
			separator = ", ";
		}
		if (!float_equal (m.carray_length_parameter_position, -3)) {
			ccode_params.append_printf ("%sarray_length_pos = %g", separator, m.carray_length_parameter_position);
			separator = ", ";
		}
		if (!float_equal (m.cdelegate_target_parameter_position, -3)) {
			ccode_params.append_printf ("%sdelegate_target_pos = %g", separator, m.cdelegate_target_parameter_position);
			separator = ", ";
		}
		if (m.sentinel != m.DEFAULT_SENTINEL) {
			ccode_params.append_printf ("%ssentinel = \"%s\"", separator, m.sentinel);
			separator = ", ";
		}

		if (ccode_params.len > 0) {
			write_indent ();
			write_string ("[CCode (%s)]".printf (ccode_params.str));
		}
		
		write_indent ();
		write_accessibility (m);
		
		if (m is CreationMethod) {
			var datatype = (Typesymbol) m.parent_symbol;
			write_identifier (datatype.name);
			write_identifier (m.name.offset (".new".len ()));
			write_string (" ");
		} else if (m.binding == MemberBinding.STATIC) {
			write_string ("static ");
		} else if (m.binding == MemberBinding.CLASS) {
			write_string ("class ");
		} else if (m.is_abstract) {
			write_string ("abstract ");
		} else if (m.is_virtual) {
			write_string ("virtual ");
		}
		
		if (!(m is CreationMethod)) {
			write_return_type (m.return_type);
			write_string (" ");

			write_identifier (m.name);
			write_string (" ");
		}
		
		write_params (m.get_parameters ());
		write_error_domains (m.get_error_types ());

		write_string (";");

		write_newline ();
	}
	
	public override void visit_creation_method (CreationMethod m) {
		visit_method (m);
	}

	public override void visit_property (Property prop) {
		if (!check_accessibility (prop) || prop.overrides || prop.base_interface_property != null) {
			return;
		}

		if (prop.no_accessor_method) {
			write_indent ();
			write_string ("[NoAccessorMethod]");
		}
		
		write_indent ();
		write_accessibility (prop);

		if (prop.is_abstract) {
			write_string ("abstract ");
		} else if (prop.is_virtual) {
			write_string ("virtual ");
		}

		write_type (prop.property_type);

		if (prop.property_type.value_owned) {
			write_string ("#");
		}

		write_string (" ");
		write_identifier (prop.name);
		write_string (" {");
		if (prop.get_accessor != null) {
			write_string (" get;");
		}
		if (prop.set_accessor != null) {
			if (prop.set_accessor.writable) {
				write_string (" set");
			}
			if (prop.set_accessor.construction) {
				write_string (" construct");
			}
			write_string (";");
		}
		write_string (" }");
		write_newline ();
	}

	public override void visit_signal (Signal sig) {
		if (!check_accessibility (sig)) {
			return;
		}
		
		if (sig.has_emitter) {
			write_indent ();
			write_string ("[HasEmitter]");
		}
		
		write_indent ();
		write_accessibility (sig);
		write_string ("signal ");
		
		write_return_type (sig.return_type);
		
		write_string (" ");
		write_identifier (sig.name);
		
		write_string (" ");
		
		write_params (sig.get_parameters ());

		write_string (";");

		write_newline ();
	}

	private void write_indent () {
		int i;
		
		if (!bol) {
			stream.putc ('\n');
		}
		
		for (i = 0; i < indent; i++) {
			stream.putc ('\t');
		}
		
		bol = false;
	}
	
	private void write_identifier (string s) {
		if (s == "base" || s == "break" || s == "class" ||
		    s == "construct" || s == "delegate" || s == "delete" ||
		    s == "do" || s == "foreach" || s == "in" ||
		    s == "interface" || s == "lock" || s == "namespace" ||
		    s == "new" || s == "out" || s == "ref" ||
		    s == "signal") {
			stream.putc ('@');
		}
		write_string (s);
	}

	private void write_return_type (DataType type) {
		if (is_weak (type)) {
			write_string ("weak ");
		}

		write_type (type);
	}

	private bool is_weak (DataType type) {
		if (type.value_owned) {
			return false;
		} else if (type is VoidType || type is PointerType) {
			return false;
		} else if (type is ValueType) {
			if (type.nullable) {
				// nullable structs are heap allocated
				return false;
			}

			// TODO return true for structs with destroy
			return false;
		}

		return true;
	}

	private void write_type (DataType type) {
		write_string (type.to_qualified_string (current_scope));
	}

	private void write_string (string s) {
		stream.printf ("%s", s);
		bol = false;
	}
	
	private void write_newline () {
		stream.putc ('\n');
		bol = true;
	}
	
	private void write_begin_block () {
		if (!bol) {
			stream.putc (' ');
		} else {
			write_indent ();
		}
		stream.putc ('{');
		write_newline ();
		indent++;
	}
	
	private void write_end_block () {
		indent--;
		write_indent ();
		stream.printf ("}");
	}

	private bool check_accessibility (Symbol sym) {
		if (sym.access == SymbolAccessibility.PUBLIC ||
		    sym.access == SymbolAccessibility.PROTECTED) {
			return true;
		}

		return false;
	}

	private void write_accessibility (Symbol sym) {
		if (sym.access == SymbolAccessibility.PUBLIC) {
			write_string ("public ");
		} else if (sym.access == SymbolAccessibility.PROTECTED) {
			write_string ("protected ");
		} else {
			assert_not_reached ();
		}
	}
}
