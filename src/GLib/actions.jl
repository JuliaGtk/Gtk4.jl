function GSimpleAction(name::AbstractString, param_type = nothing, state = nothing)
    if state === nothing
        G_.SimpleAction_new(name, param_type)
    else
        G_.SimpleAction_new_stateful(name, param_type, state)
    end
end

push!(m::GActionMap, a::GAction) = (G_.add_action(m,a); m)
delete!(m::GActionMap, a::AbstractString) = (G_.remove_action(m, a); m)

push!(g::GSimpleActionGroup, a) = (push!(GActionMap(g), GAction(a)); g)
delete!(g::GSimpleActionGroup, a::AbstractString) = (delete!(GActionMap(g), a); g)

function add_action(m::GActionMap, name::AbstractString, handler::Function)
    action = GSimpleAction(name)
    push!(m,GAction(action))
    signal_connect(handler, action, :activate)
    action
end

function add_stateful_action(m::GActionMap, name::AbstractString, initial_state, handler::Function)
    action = GSimpleAction(name, nothing, GVariant(initial_state))
    push!(m,GAction(action))
    signal_connect(handler, action, :change_state)
    action
end

set_state(m::GSimpleAction, v::GVariant) = G_.set_state(m,v)

GMenu() = G_.Menu_new()
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
