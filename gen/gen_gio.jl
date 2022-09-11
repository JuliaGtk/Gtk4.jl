using GI

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:Gio,"2.0")
d = readxml(gobject_introspection_jll.find_artifact_dir()*"/share/gir-1.0/$(GI.ns_id(ns)).gir")

## structs

toplevel, exprs, exports = GI.output_exprs()

disguised = GI.read_disguised(d)
struct_skiplist=vcat(disguised, [:ActionEntry,:DBusAnnotationInfo,:DBusArgInfo,:DBusInterfaceInfo,
:DBusInterfaceVTable,:DBusMethodInfo,:DBusPropertyInfo,:DBusSignalInfo,:DBusSubtreeVTable,
:DBusNodeInfo,:InputMessage,:OutputMessage,:StaticResource,:UnixMountEntry,:UnixMountPoint])

struct_skiplist,c = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist,output_cache_init=false)
GI.append_struc_docs!(exprs, "gio", d, c, ns)

## objects

obj_skiplist=[:UnixMountMonitor,:UnixOutputStream,:UnixInputStream,:UnixFDList,:UnixFDMessage,:UnixSocketAddress,:DebugControllerDBus]
c = GI.all_objects!(exprs,exports,ns;skiplist=obj_skiplist,output_cache_define=false,output_cache_init=false)
GI.append_object_docs!(exprs, "gio", d, c, ns)
GI.all_interfaces!(exprs,exports,ns;skiplist=[:DebugController,:PowerProfileMonitor])

push!(exprs,exports)

GI.write_to_file(path,"gio_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=struct_skiplist)

## object methods

skiplist=[:new_for_bus,:export,:add_option_group,:make_pollfd,:get_info,
:new_for_bus_sync,:new_sync,:writev,:writev_all,:flatten_tree,:changed_tree,:receive_messages,:send_message,:send_message_with_timeout,:send_messages,
:get_channel_binding_data,:lookup_certificates_issued_by,:get_default,:get_unix_fd_list,:set_unix_fd_list]

# skips are to avoid method name collisions
GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=vcat(obj_skiplist,[:AppInfoMonitor,:DBusConnection,:DBusMenuModel,:DBusProxy,:DBusMethodInvocation,:IOModule,:SimpleProxyResolver,:UnixMountMonitor,:Task]))

skiplist=[:add_action_entries,:get_info,:receive_messages,:send_messages,
:writev_nonblocking]
# skips are to avoid method name collisions
GI.all_interface_methods!(exprs,ns;skiplist=skiplist,interface_skiplist=[:App,:AppInfo,:DBusObjectManager,:Drive,:Icon,:Mount,:NetworkMonitor,:PollableOutputStream,:ProxyResolver,:SocketConnectable,:TlsBackend,:TlsClientConnection,:Volume])

GI.write_to_file(path,"gio_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

skiplist=[:bus_own_name_on_connection,:bus_own_name,:bus_watch_name_on_connection,:bus_watch_name,:dbus_annotation_info_lookup,:dbus_error_encode_gerror,:dbus_error_get_remote_error,:dbus_error_is_remote_error,:dbus_error_new_for_dbus_error,
:dbus_error_strip_remote_error,:dbus_error_register_error_domain,:io_modules_load_all_in_directory_with_scope,:io_modules_scan_all_in_directory_with_scope,:dbus_gvariant_to_gvalue,:unix_mount_at,:unix_mount_copy,:unix_mount_compare,:unix_mount_for,:unix_mount_free,
:unix_mount_get_device_path,:unix_mount_get_fs_type,:unix_mount_get_mount_path,:unix_mount_get_options,:unix_mount_get_root_path,:unix_mount_guess_can_eject,:unix_mount_guess_icon,:unix_mount_guess_name,:unix_mount_guess_should_display,:unix_mount_guess_symbolic_icon,
:unix_mount_is_readonly,:unix_mount_is_system_internal,:unix_mount_point_at,:unix_mount_points_changed_since,:unix_mount_points_get,:unix_mounts_get]

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"gio_functions",toplevel)
