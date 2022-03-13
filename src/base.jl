destroy(w::GtkWidget) = G_.destroy(w)
parent(w::GtkWidget) = G_.get_parent(w)
hasparent(w::GtkWidget) = G_.get_parent(w) !== nothing
toplevel(w::GtkWidget) = G_.get_root(w)

width(w::GtkWidget) = G_.get_allocated_width(w)
height(w::GtkWidget) = G_.get_allocated_height(w)

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = G_.get_visible(w)
visible(w::GtkWidget, state::Bool) = G_.set_visible(w,state)

function show(w::GtkWidget)
    G_.show(w)
    w
end

hide(w::GtkWidget) = (G_.hide(w); w)
grab_focus(w::GtkWidget) = (G_.grab_focus(w); w)

function iterate(w::GtkWidget, state=nothing)
    next = (state === nothing ? G_.get_first_child(w) : G_.get_next_sibling(state))
    next === nothing ? nothing : (next, next)
end

convert(::Type{GtkWidget}, w::AbstractString) = GtkLabel(w)

# Shortcut for creating callbacks that don't corrupt Gtk state if
# there's an error
macro guarded(ex...)
    retval = nothing
    if length(ex) == 2
        retval = ex[1]
        ex = ex[2]
    else
        length(ex) == 1 || error("@guarded requires 1 or 2 arguments")
        ex = ex[1]
    end
    # do-block syntax
    if ex.head == :do && length(ex.args) >= 2 && ex.args[2].head == :->
        newbody = _guarded(ex.args[2], retval)
        ret = deepcopy(ex)
        ret.args[2] = Expr(ret.args[2].head, ret.args[2].args[1], newbody)
        return esc(ret)
    end
    newbody = _guarded(ex, retval)
    esc(Expr(ex.head, ex.args[1], newbody))
end

function _guarded(ex, retval)
    isa(ex, Expr) && (
        ex.head == :-> ||
        (ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :call) ||
        ex.head == :function
    ) || error("@guarded requires an expression defining a function")
    quote
        begin
            try
                $(ex.args[2])
            catch err
                @warn("Error in @guarded callback", exception=(err, catch_backtrace()))
                $retval
            end
        end
    end
end
