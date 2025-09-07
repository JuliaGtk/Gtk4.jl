using GI, EzXML
GI.prepend_search_path("/usr/lib64/girepository-1.0")

printstyled("Generating code for Gio\n";bold=true)

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:Gio,"2.0")
d = readxml("/usr/share/gir-1.0/$(GI.ns_id(ns)).gir")

## structs

disguised = GI.read_disguised(d)
println(disguised)
struct_skiplist=vcat(disguised, [:ActionEntry,:DBusAnnotationInfo,:DBusArgInfo,:DBusInterfaceInfo,
:DBusInterfaceVTable,:DBusMethodInfo,:DBusPropertyInfo,:DBusSignalInfo,:DBusSubtreeVTable,
:DBusNodeInfo,:InputMessage,:OutputMessage,:StaticResource,:UnixMountEntry,:UnixMountPoint,
:XdpDocumentsProxy,:XdpDocumentsSkeleton,:XdpOpenURISkeleton,:XdpDocumentsProxyClass,
:XdpDocumentsSkeletonClass,:XdpOpenURIProxy,:XdpOpenURIProxyClass,:XdpOpenURISkeletonClass,
:XdpProxyResolverProxy,:XdpProxyResolverProxyClass,:XdpProxyResolverSkeleton,
:XdpProxyResolverSkeletonClass,:XdpTrashProxy,:XdpTrashProxyClass,:XdpTrashSkeleton,
:XdpTrashSkeletonClass,:_FreedesktopDBusProxyClass,:_FreedesktopDBusSkeletonClass,])

obj_skiplist=[:UnixMountMonitor,:UnixOutputStream,:UnixInputStream,:UnixFDList,:UnixFDMessage,:UnixSocketAddress,:DebugControllerDBus,:DBusInterfaceSkeleton,:DBusObjectSkeleton,:DBusObjectManagerServer]

obj_constructor_skiplist = [:new_for_bus_sync,:new_sync,:new_with_fd_list,:new_for_address_finish,:new_for_bus_finish,:new_for_bus_finish,:new_from_filename,:new_loopback,:new_section,:new_with_default_fallbacks,:new_from_file_with_password]

#GI.all_object_signals!(exprs,ns;object_skiplist=vcat(obj_skiplist,[:AppInfoMonitor,:DBusConnection,:DBusMenuModel,:DBusProxy,:DBusMethodInvocation,:IOModule,:SimpleProxyResolver,:UnixMountMonitor,:Task]))

struct_skiplist = GI.export_struct_exprs!(ns,path, "gio", struct_skiplist, []; doc_xml = d, output_boxed_cache_init = false, output_object_cache_init = false, object_skiplist = obj_skiplist, object_constructor_skiplist = obj_constructor_skiplist, interface_skiplist = [:XdpProxyResolverIface], output_object_cache_define = false, output_boxed_types_def = false)

object_method_skiplist=[:new_for_bus,:export,:add_option_group,:make_pollfd,:get_info,
:new_for_bus_sync,:new_sync,:writev,:writev_all,:flatten_tree,:changed_tree,:receive_messages,:send_message,:send_message_with_timeout,:send_messages,
:get_channel_binding_data,:lookup_certificates_issued_by,:get_default,:get_unix_fd_list,:set_unix_fd_list,:get_attribute_file_path,:set_attribute_file_path,:bind_with_mapping]

object_skiplist=vcat(obj_skiplist,[:AppInfoMonitor,:DBusConnection,:DBusMenuModel,:DBusProxy,:DBusMethodInvocation,:IOModule,:SimpleProxyResolver,:UnixMountMonitor])

interface_method_skiplist=[:add_action_entries,:get_info,:receive_messages,:send_messages,
:writev_nonblocking,:dup_default,:remove_action_entries,:new_build_filenamev,:copy_async,:move_async]
# skips are to avoid method name collisions

interface_skiplist=[:App,:DBusObjectManager,:Drive,:Icon,:Mount,:NetworkMonitor,:PollableOutputStream,:ProxyResolver,:SocketConnectable,:TlsBackend,:TlsClientConnection,:Volume,:DtlsServerConnection]

GI.export_methods!(ns,path,"gio"; interface_method_skiplist = interface_method_skiplist, interface_skiplist = interface_skiplist, object_method_skiplist = object_method_skiplist, object_skiplist = object_skiplist, struct_skiplist = struct_skiplist)

skiplist=[:bus_own_name_on_connection,:bus_own_name,:bus_watch_name_on_connection,:bus_watch_name,:dbus_annotation_info_lookup,:dbus_error_encode_gerror,:dbus_error_get_remote_error,:dbus_error_is_remote_error,:dbus_error_new_for_dbus_error,
:dbus_error_strip_remote_error,:dbus_error_register_error_domain,:io_modules_load_all_in_directory_with_scope,:io_modules_scan_all_in_directory_with_scope,:dbus_gvariant_to_gvalue,:unix_mount_at,:unix_mount_copy,:unix_mount_compare,:unix_mount_for,:unix_mount_free,
:unix_mount_get_device_path,:unix_mount_get_fs_type,:unix_mount_get_mount_path,:unix_mount_get_options,:unix_mount_get_root_path,:unix_mount_guess_can_eject,:unix_mount_guess_icon,:unix_mount_guess_name,:unix_mount_guess_should_display,:unix_mount_guess_symbolic_icon,
:unix_mount_is_readonly,:unix_mount_is_system_internal,:unix_mount_point_at,:unix_mount_points_changed_since,:unix_mount_points_get,:unix_mounts_get,:file_new_build_filenamev,:io_extension_point_implement,:io_extension_point_lookup,:io_extension_point_register,
:unix_mount_points_get_from_file,:unix_mounts_get_from_file,:unix_mount_entries_get,:unix_mount_entries_get_from_file,:unix_mount_entry_at,:unix_mount_entry_for]

GI.export_functions!(ns,path,"gio"; skiplist = skiplist)
