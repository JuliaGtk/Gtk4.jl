# actions
GSimpleAction(name::AbstractString; kwargs...) = GSimpleAction(name, nothing; kwargs...)
set_state(m::GSimpleAction, v::GVariant) = G_.set_state(m,v)

# action maps
push!(m::GActionMap, a::GAction) = (G_.add_action(m,a); m)
delete!(m::GActionMap, a::AbstractString) = (G_.remove_action(m, a); m)

function add_action(m::GActionMap, name::AbstractString, handler::Function)
    action = GSimpleAction(name)
    push!(m,GAction(action))
    signal_connect(handler, action, :activate)
    action
end

function add_action(m::GActionMap, name::AbstractString, cb, user_data)
    action = GSimpleAction(name)
    push!(m,GAction(action))
    signal_connect(cb, action, :activate, Nothing,
                   (Ptr{GVariant},), false, user_data)
    action
end

function add_stateful_action(m::GActionMap, name::AbstractString, initial_state, handler::Function)
    action = GSimpleAction(name, nothing, GVariant(initial_state))
    push!(m,GAction(action))
    signal_connect(handler, action, :change_state)
    action
end

# action groups
push!(g::GSimpleActionGroup, a) = (push!(GActionMap(g), GAction(a)); g)
delete!(g::GSimpleActionGroup, a::AbstractString) = (delete!(GActionMap(g), a); g)
list_actions(g) = G_.list_actions(GActionGroup(g))

function GDBusActionGroup(app::GApplication, bus_name, object_path)
    conn = G_.get_dbus_connection(app)
    G_.get(conn, bus_name, object_path)
end

function GMenu(i::GMenuItem)
    m = GMenu()
    G_.set_submenu(i,m)
    m
end
GMenuItem(label,detailed_action = nothing) = G_.MenuItem_new(label, detailed_action)

push!(m::GMenu, i::GMenuItem) = (G_.append_item(m,i); m)
pushfirst!(m::GMenu, i::GMenuItem) = (G_.prepend_item(m,i); m)
length(m::GMenu) = G_.get_n_items(m)

section(m::GMenu, label::AbstractString, section) = G_.append_section(m, label, section)
submenu(m::GMenu, label::AbstractString, submenu) = G_.append_submenu(m, label, submenu)
