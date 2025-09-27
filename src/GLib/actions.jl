# actions
"""
    activate(a::GAction, par = nothing)

Activates an action, optionally with a parameter `par`, which if given should be a GVariant.
"""
activate(a::GAction, par = nothing) = G_.activate(a, par)
GSimpleAction(name::AbstractString; kwargs...) = GSimpleAction(name, nothing; kwargs...)

function GSimpleAction(name::AbstractString, parameter::Type{T}; kwargs...) where T
    pvtype = parameter == Nothing ? nothing : GVariantType(parameter)
    GSimpleAction(name, pvtype)
end

"""
    GSimpleAction(name::AbstractString, 
                  [parameter_type::Type{T}, [initial_state]]; kwargs...) where T

Create an action with a `name` and optionally a `parameter_type` from a Julia
type (only a few simple types are supported) and an `initial_state`. If
`initial_state` is not provided, the action will be stateless.

Keyword arguments set the action's GObject properties.
"""
function GSimpleAction(name::AbstractString, parameter::Type{T},
                       initial_state; kwargs...) where T
    pvtype = parameter == Nothing ? nothing : GVariantType(parameter)
    GSimpleAction(name, pvtype, GVariant(initial_state))
end

activate(a::GSimpleAction, par = nothing) = G_.activate(GAction(a), par)

"""
    set_state(m::GSimpleAction, v)

Set the state of a stateful action.
"""
set_state(m::GSimpleAction, v) = set_state(m, GVariant(v))
set_state(m::GSimpleAction, v::GVariant) = G_.set_state(m,v)

# action maps
push!(m::GActionMap, a::GAction) = (G_.add_action(m,a); m)
delete!(m::GActionMap, a::AbstractString) = (G_.remove_action(m, a); m)
getindex(m::GActionMap, name::AbstractString) = G_.lookup_action(m, name)

"""
    add_action(m::GActionMap, name::AbstractString, parameter::Type{T}, handler::Function)

Add an action with `name` and a parameter of type `T` to a `GActionMap`.
Returns the action. Also connect a `handler` for the action's "activate"
signal.
"""
function add_action(m::GActionMap, name::AbstractString,
                    parameter::Type{T}, handler::Function) where T
    action = GSimpleAction(name, parameter)
    push!(m, GAction(action))
    signal_connect(handler, action, :activate)
    action
end

"""
    add_action(m::GActionMap, name::AbstractString, handler::Function)

Add an action with `name` to a `GActionMap`. Also connect a `handler` for the
action's "activate" signal.
"""
function add_action(m::GActionMap, name::AbstractString, handler::Function)
    add_action(m, name, Nothing, handler)
end

function add_action(m::GActionMap, name::AbstractString,
                    parameter::Type{T}, cb::Function, user_data) where T
    action = GSimpleAction(name, parameter)
    push!(m,GAction(action))
    signal_connect(cb, action, :activate, Nothing,
                   (Ptr{GVariant},), false, user_data)
    action
end

function add_action(m::GActionMap, name::AbstractString, cb::Function, user_data)
    add_action(m, name, Nothing, cb, user_data)
end

"""
    add_stateful_action(m::GActionMap, name::AbstractString, parameter::Type{T}, initial_state, handler::Function)

Add a stateful action with `name`, a parameter of type `T`, and an initial state to a `GActionMap`. Also connect a `handler` for the action's "change-state" signal.
"""
function add_stateful_action(m::GActionMap, name::AbstractString,
                             parameter::Type{T}, initial_state,
                             handler::Function) where T
    action = GSimpleAction(name, parameter, initial_state)
    push!(m, GAction(action))
    signal_connect(handler, action, :change_state)
    action
end

"""
    add_stateful_action(m::GActionMap, name::AbstractString, initial_state, handler::Function)

Add a stateful action with `name` and an initial state to a `GActionMap`. Also connect a `handler` for the action's "change-state" signal.
"""
function add_stateful_action(m::GActionMap, name::AbstractString, initial_state,
                             handler::Function)
    add_stateful_action(m, name, Nothing, initial_state, handler)
end

function add_stateful_action(m::GActionMap, name::AbstractString,
                             parameter::Type{T}, initial_state,
                             cb::Function, user_data) where T
    action = GSimpleAction(name, parameter, initial_state)
    push!(m,GAction(action))
    signal_connect(cb, action, :change_state, Nothing,
                   (Ptr{GVariant},), false, user_data)
    action
end

function add_stateful_action(m::GActionMap, name::AbstractString, initial_state,
                             cb::Function, user_data)
    add_stateful_action(m, name, Nothing, initial_state, cb, user_data)
end

# action groups
push!(g::GSimpleActionGroup, a) = (push!(GActionMap(g), GAction(a)); g)
delete!(g::GSimpleActionGroup, a::AbstractString) = (delete!(GActionMap(g), a); g)
getindex(g::GSimpleActionGroup, name::AbstractString) = getindex(GActionMap(g), name)
list_actions(g) = G_.list_actions(GActionGroup(g))
Base.keys(g::GSimpleActionGroup) = G_.list_actions(GActionGroup(g))

function GDBusActionGroup(app::GApplication, bus_name, object_path)
    conn = G_.get_dbus_connection(app)
    G_.get(conn, bus_name, object_path)
end

# menus
function GMenu(i::GMenuItem)
    m = GMenu()
    G_.set_submenu(i,m)
    m
end
"""
    GMenuItem(label, [detailed_action])

Create a GMenuItem with attributes `label` and an optional `detailed_action`, which is
an action name with an optional detail argument.
"""
GMenuItem(label,detailed_action = nothing) = G_.MenuItem_new(label, detailed_action)

push!(m::GMenu, i::GMenuItem) = (G_.append_item(m,i); m)
pushfirst!(m::GMenu, i::GMenuItem) = (G_.prepend_item(m,i); m)
length(m::GMenu) = G_.get_n_items(m)

section(m::GMenu, label::AbstractString, section) = G_.append_section(m, label, section)
submenu(m::GMenu, label::AbstractString, submenu) = G_.append_submenu(m, label, submenu)
