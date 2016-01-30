/* rest-0.6.vapi generated by vapigen, do not modify. */

namespace Rest {
	[CCode (cheader_filename = "rest/oauth-proxy.h", cname = "OAuthProxy")]
	public class OAuthProxy : Rest.Proxy {
		[CCode (cname = "oauth_proxy_new", has_construct_function = false, type = "RestProxy*")]
		public OAuthProxy (string consumer_key, string consumer_secret, string url_format, bool binding_required);
		[CCode (cname = "oauth_proxy_access_token")]
		public bool access_token (string function, string verifier) throws GLib.Error;
		[CCode (cname = "oauth_proxy_access_token_async")]
		public bool access_token_async (string function, string verifier, [CCode (delegate_target_pos = 4.9)] Rest.OAuthProxyAuthCallback callback, GLib.Object? weak_object) throws GLib.Error;
		[CCode (cname = "oauth_proxy_auth_step")]
		[Version (deprecated = true)]
		public bool auth_step (string function) throws GLib.Error;
		[CCode (cname = "oauth_proxy_auth_step_async")]
		[Version (deprecated = true)]
		public bool auth_step_async (string function, [CCode (delegate_target_pos = 3.9)] Rest.OAuthProxyAuthCallback callback, GLib.Object? weak_object) throws GLib.Error;
		[CCode (cname = "oauth_proxy_get_token")]
		public unowned string get_token ();
		[CCode (cname = "oauth_proxy_get_token_secret")]
		public unowned string get_token_secret ();
		[CCode (cname = "oauth_proxy_is_oauth10a")]
		public bool is_oauth10a ();
		[CCode (cname = "oauth_proxy_request_token")]
		public bool request_token (string function, string callback_uri) throws GLib.Error;
		[CCode (cname = "oauth_proxy_request_token_async")]
		public bool request_token_async (string function, string callback_uri, [CCode (delegate_target_pos = 4.9)] Rest.OAuthProxyAuthCallback callback, GLib.Object? weak_object) throws GLib.Error;
		[CCode (cname = "oauth_proxy_set_token")]
		public void set_token (string token);
		[CCode (cname = "oauth_proxy_set_token_secret")]
		public void set_token_secret (string token_secret);
		[CCode (cname = "oauth_proxy_new_with_token", has_construct_function = false, type = "RestProxy*")]
		public OAuthProxy.with_token (string consumer_key, string consumer_secret, string token, string token_secret, string url_format, bool binding_required);
		[NoAccessorMethod]
		public string consumer_key { owned get; construct; }
		[NoAccessorMethod]
		public string consumer_secret { owned get; construct; }
		public string token { get; set; }
		public string token_secret { get; set; }
	}
	[CCode (cheader_filename = "rest/oauth-proxy-call.h")]
	public class OAuthProxyCall : Rest.ProxyCall {
		[CCode (has_construct_function = false)]
		protected OAuthProxyCall ();
	}
	[CCode (cheader_filename = "rest/rest-proxy.h")]
	public class Proxy : GLib.Object {
		[CCode (has_construct_function = false)]
		public Proxy (string url_format, bool binding_required);
		public bool bind (...);
		public virtual bool bind_valist (void* @params);
		public static GLib.Quark error_quark ();
		public unowned string get_user_agent ();
		public virtual Rest.ProxyCall new_call ();
		public void set_user_agent (string user_agent);
		public bool simple_run (string payload, int64 len) throws GLib.Error;
		public virtual bool simple_run_valist (string payload, int64 len, void* @params) throws GLib.Error;
		[NoAccessorMethod]
		public bool binding_required { get; set; }
		[NoAccessorMethod]
		public string url_format { owned get; set; }
		public string user_agent { get; set; }
	}
	[CCode (cheader_filename = "rest/rest-proxy-call.h")]
	public class ProxyCall : GLib.Object {
		[CCode (has_construct_function = false)]
		protected ProxyCall ();
		public void add_header (string header, string value);
		public void add_headers (...);
		public void add_headers_from_valist (void* headers);
		public void add_param (string param, string value);
		public void add_params (...);
		public void add_params_from_valist (void* @params);
		public bool cancel ();
		public static GLib.Quark error_quark ();
		public unowned string get_method ();
		public GLib.HashTable<string,string> get_params ();
		public unowned string get_payload ();
		public int64 get_payload_length ();
		public unowned GLib.HashTable get_response_headers ();
		public uint get_status_code ();
		public unowned string get_status_message ();
		public unowned string lookup_header (string header);
		public unowned string lookup_param (string param);
		public unowned string lookup_response_header (string header);
		[NoWrapper]
		public virtual bool prepare () throws GLib.Error;
		public void remove_header (string header);
		public void remove_param (string param);
		public bool run (out unowned GLib.MainLoop loop) throws GLib.Error;
		[CCode (cname = "rest_proxy_call_async")]
		public bool run_async ([CCode (delegate_target_pos = 2.9)] Rest.ProxyCallAsyncCallback callback, GLib.Object? weak_object) throws GLib.Error;
		public void set_function (string function);
		public void set_method (string method);
		public bool sync () throws GLib.Error;
		[NoAccessorMethod]
		public Rest.Proxy proxy { owned get; construct; }
	}
	[CCode (cheader_filename = "rest/rest-xml-parser.h", ref_function = "rest_xml_node_ref", type_id = "rest_xml_node_get_type ()", unref_function = "rest_xml_node_unref")]
	[Compact]
	public class XmlNode {
		public weak GLib.HashTable attrs;
		public weak GLib.HashTable children;
		public weak string content;
		public weak string name;
		public weak Rest.XmlNode next;
		public int ref_count;
		public unowned Rest.XmlNode find (string tag);
		public unowned string get_attr (string attr_name);
	}
	[CCode (cheader_filename = "rest/rest-xml-parser.h")]
	public class XmlParser : GLib.Object {
		[CCode (has_construct_function = false)]
		public XmlParser ();
		public unowned Rest.XmlNode parse_from_data (string data, int64 len);
	}
	[CCode (cheader_filename = "rest/oauth-proxy.h", cprefix = "", has_type_id = false)]
	public enum OAuthSignatureMethod {
		PLAINTEXT,
		HMAC_SHA1
	}
	[CCode (cheader_filename = "rest/rest-proxy-call.h", cprefix = "REST_PROXY_CALL_")]
	public errordomain ProxyCallError {
		FAILED
	}
	[CCode (cheader_filename = "rest/rest-proxy.h", cprefix = "REST_PROXY_ERROR_")]
	public errordomain ProxyError {
		CANCELLED,
		RESOLUTION,
		CONNECTION,
		SSL,
		IO,
		FAILED,
		HTTP_MULTIPLE_CHOICES,
		HTTP_MOVED_PERMANENTLY,
		HTTP_FOUND,
		HTTP_SEE_OTHER,
		HTTP_NOT_MODIFIED,
		HTTP_USE_PROXY,
		HTTP_THREEOHSIX,
		HTTP_TEMPORARY_REDIRECT,
		HTTP_BAD_REQUEST,
		HTTP_UNAUTHORIZED,
		HTTP_FOUROHTWO,
		HTTP_FORBIDDEN,
		HTTP_NOT_FOUND,
		HTTP_METHOD_NOT_ALLOWED,
		HTTP_NOT_ACCEPTABLE,
		HTTP_PROXY_AUTHENTICATION_REQUIRED,
		HTTP_REQUEST_TIMEOUT,
		HTTP_CONFLICT,
		HTTP_GONE,
		HTTP_LENGTH_REQUIRED,
		HTTP_PRECONDITION_FAILED,
		HTTP_REQUEST_ENTITY_TOO_LARGE,
		HTTP_REQUEST_URI_TOO_LONG,
		HTTP_UNSUPPORTED_MEDIA_TYPE,
		HTTP_REQUESTED_RANGE_NOT_SATISFIABLE,
		HTTP_EXPECTATION_FAILED,
		HTTP_INTERNAL_SERVER_ERROR,
		HTTP_NOT_IMPLEMENTED,
		HTTP_BAD_GATEWAY,
		HTTP_SERVICE_UNAVAILABLE,
		HTTP_GATEWAY_TIMEOUT,
		HTTP_HTTP_VERSION_NOT_SUPPORTED
	}
	[CCode (cheader_filename = "rest/oauth-proxy.h")]
	public delegate void OAuthProxyAuthCallback (Rest.OAuthProxy proxy, GLib.Error? error, GLib.Object? weak_object);
	[CCode (cheader_filename = "rest/rest-proxy-call.h")]
	public delegate void ProxyCallAsyncCallback (Rest.ProxyCall call, GLib.Error? error, GLib.Object? weak_object);
}
