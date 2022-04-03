function GSimpleAction(name::AbstractString, param_type = nothing, state = nothing)
    if state === nothing
        G_.SimpleAction_new(name, param_type)
    else
        G_.SimpleAction_new_stateful(name, param_type, state)
    end
end

push!(m::GActionMap, a::GAction) = G_.add_action(m,a)

function add_action(m::GActionMap, name::AbstractString, handler::Function)
    action = GSimpleAction(name)
    push!(m,GAction(action))
    signal_connect(handler, action, :activate)
end

function add_stateful_action(m::GActionMap, name::AbstractString, initial_state, handler::Function)
    action = GSimpleAction(name, nothing, GVariant(initial_state))
    push!(m,GAction(action))
    signal_connect(handler, action, :change_state)
end

set_state(m::GSimpleAction, v::GVariant) = G_.set_state(m,v)

GApplication(id = nothing, flags = GLib.Constants.ApplicationFlags_FLAGS_NONE) = G_.Application_new(id,flags)

function run(app::GApplication)
    ccall(("g_application_run", libgio), Int32, (Ptr{GObject}, Int32, Ptr{Cstring}), app, 0, C_NULL)
end
register(app::GApplication) = G_.register(app, nothing)
activate(app::GApplication) = G_.activate(app)
