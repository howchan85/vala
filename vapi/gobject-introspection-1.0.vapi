/* gobject-introspection-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "GI", gir_namespace = "GIRepository", gir_version = "2.0", lower_case_cprefix = "g_")]
namespace GI {
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class ArgInfo : GI.BaseInfo {
		public int get_closure ();
		public int get_destroy ();
		public GI.Direction get_direction ();
		public GI.Transfer get_ownership_transfer ();
		public GI.ScopeType get_scope ();
		public GI.TypeInfo get_type ();
		public bool is_caller_allocates ();
		public bool is_optional ();
		public bool is_return_value ();
		[Version (since = "1.30")]
		public bool is_skip ();
		public void load_type (out unowned GI.TypeInfo type);
		public bool may_be_null ();
	}
	[CCode (cheader_filename = "girepository.h", lower_case_cprefix = "g_base_info_", lower_case_csuffix = "base_info_gtype", ref_function = "g_base_info_ref", type_id = "g_base_info_gtype_get_type ()", unref_function = "g_base_info_unref")]
	[Compact]
	public class BaseInfo {
		[CCode (cname = "g_info_new")]
		public BaseInfo (GI.InfoType type, GI.BaseInfo container, GI.Typelib typelib, uint32 offset);
		public bool equal (GI.BaseInfo info2);
		public unowned string get_attribute (string name);
		public unowned GI.BaseInfo get_container ();
		public unowned string get_name ();
		public unowned string get_namespace ();
		public GI.InfoType get_type ();
		public unowned GI.Typelib get_typelib ();
		public bool is_deprecated ();
		public bool iterate_attributes (ref GI.AttributeIter iterator, out unowned string name, out unowned string value);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class CallableInfo : GI.BaseInfo {
		[Version (since = "1.34")]
		public bool can_throw_gerror ();
		public GI.ArgInfo get_arg (int n);
		public GI.Transfer get_caller_owns ();
		[Version (since = "1.42")]
		public GI.Transfer get_instance_ownership_transfer ();
		public int get_n_args ();
		public unowned string get_return_attribute (string name);
		public GI.TypeInfo get_return_type ();
		public bool invoke (void* function, [CCode (array_length_cname = "n_in_args", array_length_pos = 2.5)] GI.Argument[] in_args, [CCode (array_length_cname = "n_out_args", array_length_pos = 3.5)] GI.Argument[] out_args, GI.Argument return_value, bool is_method, bool @throws) throws GI.InvokeError;
		[Version (since = "1.34")]
		public bool is_method ();
		public bool iterate_return_attributes (ref GI.AttributeIter iterator, out unowned string name, out unowned string value);
		public void load_arg (int n, out unowned GI.ArgInfo arg);
		public void load_return_type (out unowned GI.TypeInfo type);
		public bool may_return_null ();
		public bool skip_return ();
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class CallbackInfo : GI.CallableInfo {
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class ConstantInfo : GI.BaseInfo {
		[Version (since = "1.32")]
		public void free_value (GI.Argument value);
		public GI.TypeInfo get_type ();
		public int get_value (out GI.Argument value);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class EnumInfo : GI.BaseInfo {
		[Version (since = "1.30")]
		public unowned string get_error_domain ();
		[Version (since = "1.30")]
		public GI.FunctionInfo get_method (int n);
		[Version (since = "1.30")]
		public int get_n_methods ();
		public int get_n_values ();
		public GI.TypeTag get_storage_type ();
		public GI.ValueInfo get_value (int n);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class FieldInfo : GI.BaseInfo {
		public bool get_field (void* mem, GI.Argument value);
		public GI.FieldInfoFlags get_flags ();
		public int get_offset ();
		public int get_size ();
		public GI.TypeInfo get_type ();
		public bool set_field (void* mem, GI.Argument value);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class FunctionInfo : GI.CallableInfo {
		public GI.FunctionInfoFlags get_flags ();
		public GI.PropertyInfo get_property ();
		public unowned string get_symbol ();
		public GI.VFuncInfo get_vfunc ();
		public bool invoke ([CCode (array_length_cname = "n_in_args", array_length_pos = 1.5)] GI.Argument[] in_args, [CCode (array_length_cname = "n_out_args", array_length_pos = 2.5)] GI.Argument[] out_args, GI.Argument return_value) throws GI.InvokeError;
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class InterfaceInfo : GI.BaseInfo {
		public GI.FunctionInfo find_method (string name);
		[Version (since = "1.34")]
		public GI.SignalInfo find_signal (string name);
		public GI.VFuncInfo find_vfunc (string name);
		public GI.ConstantInfo get_constant (int n);
		public GI.StructInfo get_iface_struct ();
		public GI.FunctionInfo get_method (int n);
		public int get_n_constants ();
		public int get_n_methods ();
		public int get_n_prerequisites ();
		public int get_n_properties ();
		public int get_n_signals ();
		public int get_n_vfuncs ();
		public GI.BaseInfo get_prerequisite (int n);
		public GI.PropertyInfo get_property (int n);
		public GI.SignalInfo get_signal (int n);
		public GI.VFuncInfo get_vfunc (int n);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class ObjectInfo : GI.BaseInfo {
		public GI.FunctionInfo find_method (string name);
		public GI.FunctionInfo find_method_using_interfaces (string name, out GI.ObjectInfo implementor);
		public GI.SignalInfo find_signal (string name);
		public GI.VFuncInfo find_vfunc (string name);
		public GI.VFuncInfo find_vfunc_using_interfaces (string name, out GI.ObjectInfo implementor);
		public bool get_abstract ();
		public GI.StructInfo get_class_struct ();
		public GI.ConstantInfo get_constant (int n);
		public GI.FieldInfo get_field (int n);
		public bool get_fundamental ();
		public unowned string get_get_value_function ();
		public unowned GI.ObjectInfoGetValueFunction get_get_value_function_pointer ();
		public GI.InterfaceInfo get_interface (int n);
		public GI.FunctionInfo get_method (int n);
		public int get_n_constants ();
		public int get_n_fields ();
		public int get_n_interfaces ();
		public int get_n_methods ();
		public int get_n_properties ();
		public int get_n_signals ();
		public int get_n_vfuncs ();
		public GI.ObjectInfo get_parent ();
		public GI.PropertyInfo get_property (int n);
		public unowned string get_ref_function ();
		public unowned GI.ObjectInfoRefFunction get_ref_function_pointer ();
		public unowned string get_set_value_function ();
		public unowned GI.ObjectInfoSetValueFunction get_set_value_function_pointer ();
		public GI.SignalInfo get_signal (int n);
		public unowned string get_type_init ();
		public unowned string get_type_name ();
		public unowned string get_unref_function ();
		public unowned GI.ObjectInfoUnrefFunction get_unref_function_pointer ();
		public GI.VFuncInfo get_vfunc (int n);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class PropertyInfo : GI.BaseInfo {
		public GLib.ParamFlags get_flags ();
		public GI.Transfer get_ownership_transfer ();
		public GI.TypeInfo get_type ();
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class RegisteredTypeInfo : GI.BaseInfo {
		public GLib.Type get_g_type ();
		public unowned string get_type_init ();
		public unowned string get_type_name ();
	}
	[CCode (cheader_filename = "girepository.h", lower_case_csuffix = "irepository", type_id = "g_irepository_get_type ()")]
	public class Repository : GLib.Object {
		[CCode (has_construct_function = false)]
		protected Repository ();
		public static bool dump (string arg) throws GI.RepositoryError;
		public GLib.List<string> enumerate_versions (string namespace_);
		[Version (since = "1.30")]
		public GI.EnumInfo find_by_error_domain (GLib.Quark domain);
		public GI.BaseInfo find_by_gtype (GLib.Type gtype);
		public GI.BaseInfo find_by_name (string namespace_, string name);
		public unowned string get_c_prefix (string namespace_);
		public static unowned GI.Repository get_default ();
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] get_dependencies (string namespace_);
		[CCode (array_length = false, array_null_terminated = true)]
		[Version (since = "1.44")]
		public string[] get_immediate_dependencies (string namespace_);
		public GI.BaseInfo get_info (string namespace_, int index);
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] get_loaded_namespaces ();
		public int get_n_infos (string namespace_);
		public static GLib.OptionGroup get_option_group ();
		public static unowned GLib.SList<string> get_search_path ();
		public unowned string get_shared_library (string namespace_);
		public unowned string get_typelib_path (string namespace_);
		public unowned string get_version (string namespace_);
		public bool is_registered (string namespace_, string? version);
		public unowned string load_typelib (GI.Typelib typelib, GI.RepositoryLoadFlags flags) throws GI.RepositoryError;
		public static void prepend_library_path (string directory);
		public static void prepend_search_path (string directory);
		public unowned GI.Typelib require (string namespace_, string? version, GI.RepositoryLoadFlags flags) throws GI.RepositoryError;
		public unowned GI.Typelib require_private (string typelib_dir, string namespace_, string? version, GI.RepositoryLoadFlags flags) throws GLib.Error;
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class SignalInfo : GI.CallableInfo {
		public GI.VFuncInfo get_class_closure ();
		public GLib.SignalFlags get_flags ();
		public bool true_stops_emit ();
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class StructInfo : GI.BaseInfo {
		[Version (since = "1.46")]
		public GI.FieldInfo find_field (string name);
		public GI.FunctionInfo find_method (string name);
		public size_t get_alignment ();
		public GI.FieldInfo get_field (int n);
		public GI.FunctionInfo get_method (int n);
		public int get_n_fields ();
		public int get_n_methods ();
		public size_t get_size ();
		public bool is_foreign ();
		public bool is_gtype_struct ();
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class TypeInfo : GI.BaseInfo {
		public int get_array_fixed_size ();
		public int get_array_length ();
		public GI.ArrayType get_array_type ();
		public GI.BaseInfo get_interface ();
		public GI.TypeInfo get_param_type (int n);
		public GI.TypeTag get_tag ();
		public bool is_pointer ();
		public bool is_zero_terminated ();
	}
	[CCode (cheader_filename = "girepository.h", has_type_id = false)]
	[Compact]
	public class Typelib {
		public void free ();
		public unowned string get_namespace ();
		public bool symbol (string symbol_name, out void* symbol);
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class UnionInfo : GI.BaseInfo {
		public GI.FunctionInfo find_method (string name);
		public size_t get_alignment ();
		public GI.ConstantInfo get_discriminator (int n);
		public int get_discriminator_offset ();
		public GI.TypeInfo get_discriminator_type ();
		public GI.FieldInfo get_field (int n);
		public GI.FunctionInfo get_method (int n);
		public int get_n_fields ();
		public int get_n_methods ();
		public size_t get_size ();
		public bool is_discriminated ();
	}
	[CCode (cheader_filename = "girepository.h", has_type_id = false)]
	[Compact]
	public class UnresolvedInfo {
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class VFuncInfo : GI.CallableInfo {
		public void* get_address (GLib.Type implementor_gtype) throws GLib.Error;
		public GI.VFuncInfoFlags get_flags ();
		public GI.FunctionInfo get_invoker ();
		public int get_offset ();
		public GI.SignalInfo get_signal ();
		public bool invoke (GLib.Type implementor, [CCode (array_length_cname = "n_in_args", array_length_pos = 2.5)] GI.Argument[] in_args, [CCode (array_length_cname = "n_out_args", array_length_pos = 3.5)] GI.Argument[] out_args, GI.Argument return_value) throws GI.InvokeError;
	}
	[CCode (cheader_filename = "girepository.h", type_id = "g_base_info_gtype_get_type ()")]
	[Compact]
	public class ValueInfo : GI.BaseInfo {
		public int64 get_value ();
	}
	[CCode (cheader_filename = "girepository.h")]
	public struct Argument {
		public bool v_boolean;
		public int8 v_int8;
		public uint8 v_uint8;
		public int16 v_int16;
		public uint16 v_uint16;
		public int32 v_int32;
		public uint32 v_uint32;
		public int64 v_int64;
		public uint64 v_uint64;
		public float v_float;
		public double v_double;
		public short v_short;
		public ushort v_ushort;
		public int v_int;
		public uint v_uint;
		public long v_long;
		public ulong v_ulong;
		public ssize_t v_ssize;
		public size_t v_size;
		public weak string v_string;
		public void* v_pointer;
	}
	[CCode (cheader_filename = "girepository.h", has_type_id = false)]
	public struct AttributeIter {
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_ARRAY_TYPE_", has_type_id = false)]
	public enum ArrayType {
		C,
		ARRAY,
		PTR_ARRAY,
		BYTE_ARRAY
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_DIRECTION_", has_type_id = false)]
	public enum Direction {
		IN,
		OUT,
		INOUT
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_FIELD_IS_", has_type_id = false)]
	[Flags]
	public enum FieldInfoFlags {
		READABLE,
		WRITABLE
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_FUNCTION_", has_type_id = false)]
	[Flags]
	public enum FunctionInfoFlags {
		IS_METHOD,
		IS_CONSTRUCTOR,
		IS_GETTER,
		IS_SETTER,
		WRAPS_VFUNC,
		THROWS
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_INFO_TYPE_", has_type_id = false)]
	public enum InfoType {
		INVALID,
		FUNCTION,
		CALLBACK,
		STRUCT,
		BOXED,
		ENUM,
		FLAGS,
		OBJECT,
		INTERFACE,
		CONSTANT,
		INVALID_0,
		UNION,
		VALUE,
		SIGNAL,
		VFUNC,
		PROPERTY,
		FIELD,
		ARG,
		TYPE,
		UNRESOLVED;
		public unowned string to_string ();
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "G_IREPOSITORY_LOAD_FLAG_", has_type_id = false)]
	[Flags]
	public enum RepositoryLoadFlags {
		[CCode (cname = "G_IREPOSITORY_LOAD_FLAG_LAZY")]
		IREPOSITORY_LOAD_FLAG_LAZY
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_SCOPE_TYPE_", has_type_id = false)]
	public enum ScopeType {
		INVALID,
		CALL,
		ASYNC,
		NOTIFIED
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_TRANSFER_", has_type_id = false)]
	public enum Transfer {
		NOTHING,
		CONTAINER,
		EVERYTHING
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_TYPE_TAG_", has_type_id = false)]
	public enum TypeTag {
		VOID,
		BOOLEAN,
		INT8,
		UINT8,
		INT16,
		UINT16,
		INT32,
		UINT32,
		INT64,
		UINT64,
		FLOAT,
		DOUBLE,
		GTYPE,
		UTF8,
		FILENAME,
		ARRAY,
		INTERFACE,
		GLIST,
		GSLIST,
		GHASH,
		ERROR,
		UNICHAR;
		public unowned string to_string ();
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "GI_VFUNC_", has_type_id = false)]
	[Flags]
	public enum VFuncInfoFlags {
		MUST_CHAIN_UP,
		MUST_OVERRIDE,
		MUST_NOT_OVERRIDE,
		THROWS
	}
	[CCode (cheader_filename = "girepository.h", cname = "GInvokeError", cprefix = "G_INVOKE_ERROR_", has_type_id = false)]
	[GIR (name = "nvokeError")]
	public errordomain InvokeError {
		FAILED,
		SYMBOL_NOT_FOUND,
		ARGUMENT_MISMATCH;
		public static GLib.Quark quark ();
	}
	[CCode (cheader_filename = "girepository.h", cprefix = "G_IREPOSITORY_ERROR_", has_type_id = false)]
	public errordomain RepositoryError {
		TYPELIB_NOT_FOUND,
		NAMESPACE_MISMATCH,
		NAMESPACE_VERSION_CONFLICT,
		LIBRARY_NOT_FOUND;
		[CCode (cname = "g_irepository_error_quark")]
		public static GLib.Quark quark ();
	}
	[CCode (cheader_filename = "girepository.h", has_target = false)]
	public delegate void* ObjectInfoGetValueFunction (GLib.Value value);
	[CCode (cheader_filename = "girepository.h", has_target = false)]
	public delegate void* ObjectInfoRefFunction (void* object);
	[CCode (cheader_filename = "girepository.h", has_target = false)]
	public delegate void ObjectInfoSetValueFunction (GLib.Value value, void* object);
	[CCode (cheader_filename = "girepository.h", has_target = false)]
	public delegate void ObjectInfoUnrefFunction (void* object);
	[CCode (cheader_filename = "girepository.h", cname = "GI_MAJOR_VERSION")]
	[Version (since = "1.60")]
	public const int MAJOR_VERSION;
	[CCode (cheader_filename = "girepository.h", cname = "GI_MICRO_VERSION")]
	[Version (since = "1.60")]
	public const int MICRO_VERSION;
	[CCode (cheader_filename = "girepository.h", cname = "GI_MINOR_VERSION")]
	[Version (since = "1.60")]
	public const int MINOR_VERSION;
	[CCode (cheader_filename = "girepository.h", cname = "GI_TYPE_TAG_N_TYPES")]
	public const int TYPE_TAG_N_TYPES;
	[CCode (cheader_filename = "girepository.h", cname = "gi_get_major_version")]
	[Version (since = "1.60")]
	public static uint get_major_version ();
	[CCode (cheader_filename = "girepository.h", cname = "gi_get_micro_version")]
	[Version (since = "1.60")]
	public static uint get_micro_version ();
	[CCode (cheader_filename = "girepository.h", cname = "gi_get_minor_version")]
	[Version (since = "1.60")]
	public static uint get_minor_version ();
}
