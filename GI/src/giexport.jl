# functions that output expressions for a library in bulk

function _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded)
    for e in es
        name = Symbol(get_name(e))
        typeinit = in(name, skiplist) ? false : incl_typeinit
        push!(const_mod.args, unblock(decl(e,typeinit)))
        push!(const_exports.args, name)
        push!(loaded,name)
    end
end

function all_const_exprs!(const_mod, const_exports, ns;print_summary=true,incl_typeinit=true,skiplist=Symbol[])
    loaded=Symbol[]
    c = get_consts(ns)

    for (name,val) in c
        in(name, skiplist) && continue
        push!(const_mod.args, const_expr("$name",val))
        push!(loaded,name)
    end
    if print_summary && length(c)>0
        printstyled("Generated ",length(c)," constants\n";color=:green)
    end

    es=get_all(ns,GIEnumInfo)
    _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded)

    if print_summary && length(es)>0
        printstyled("Generated ",length(es)," enums\n";color=:green)
    end

    es=get_all(ns,GIFlagsInfo)
    _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded)

    if print_summary && length(es)>0
        printstyled("Generated ",length(es)," flags\n";color=:green)
    end
    loaded
end

function all_const_exprs(ns;print_summary=true)
    const_mod = Expr(:block)
    const_exports = Expr(:export)

    all_const_exprs!(const_mod,const_exports,ns;print_summary=print_summary)
    push!(const_mod.args,const_exports)

    const_mod
end

function struct_cache_expr!(exprs)
    gboxed_types_list = quote
        gboxed_types = Any[]
    end
    push!(exprs,unblock(gboxed_types_list))
end

function struct_exprs!(exprs,exports,ns,structs=nothing;print_summary=true,excludelist=[],constructor_skiplist=[],import_as_opaque=[],output_cache_init=true,only_opaque=false)
    struct_skiplist=excludelist

    if structs === nothing
        s=get_all(ns,GIStructInfo)
        structinfos=filter(p->∉(get_name(p),struct_skiplist),s)
        structs = get_name.(structinfos)
    end

    imported=length(structs)
    for ss in structs
        ssi=gi_find_by_name(ns,ss)
        name=Symbol(get_name(ssi))
        fields=get_fields(ssi)
        if only_opaque && length(fields)>0 && !in(name,import_as_opaque)
            imported-=1
            continue
        end
        if occursin("Private",String(name))
            imported-=1
            continue
        end
        if is_gtype_struct(ssi) # these are "class structures" and according to the documentation we probably don't need them in bindings
            push!(struct_skiplist,name)
            imported-=1
            continue
        end
        name = Symbol("$name")
        try
            test = coalesce(in(name,import_as_opaque),false)
            push!(exprs, decl(ssi,test))
        catch NotImplementedError
            if print_summary
                printstyled(name," not implemented\n";color=:red)
            end
            push!(struct_skiplist,name)
            imported-=1
            continue
        end
        push!(exports.args, get_full_name(ssi))
        if length(fields)>0
            push!(exports.args,get_struct_name(ssi,false))
        end
    end

    for ss in structs
        ssi=gi_find_by_name(ns,ss)
        constructors = get_constructors(ssi;skiplist=constructor_skiplist, struct_skiplist=struct_skiplist)
        if !isempty(constructors)
            append!(exprs,constructors)
        end
    end

    if print_summary
        printstyled("Generated ",imported," structs out of ",length(structs),"\n";color=:green)
    end

    struct_skiplist
end

function all_struct_exprs!(exprs,exports,ns;print_summary=true,excludelist=[],constructor_skiplist=[],import_as_opaque=Symbol[],output_cache_init=true,only_opaque=false)
    struct_skiplist=excludelist
    loaded=Symbol[]

    s=get_all(ns,GIStructInfo)
    ss=filter(p->∉(get_name(p),struct_skiplist),s)
    imported=length(ss)
    for ssi in ss
        name=get_name(ssi)
        name = Symbol("$name")
        fields=get_fields(ssi)
        if only_opaque && length(fields)>0 && !in(name,import_as_opaque)
            imported-=1
            continue
        end
        if occursin("Private",String(name))
            imported-=1
            continue
        end
        if is_gtype_struct(ssi) # these are "class structures" and according to the documentation we probably don't need them in bindings
            push!(struct_skiplist,name)
            imported-=1
            continue
        end

        push!(exprs, decl(ssi,in(name,import_as_opaque)))
        push!(exports.args, get_full_name(ssi))
        push!(loaded, name)
        if length(fields)>0
            push!(exports.args,get_struct_name(ssi,false))
        end
    end

    if output_cache_init
        gboxed_types_init = quote
            gboxed_cache_init() = append!(GLib.gboxed_types,gboxed_types)
        end
        push!(exprs,unblock(gboxed_types_init))
    end

    
    for ssi in ss
        constructors = get_constructors(ssi;skiplist=constructor_skiplist, struct_skiplist=struct_skiplist)
        if !isempty(constructors)
            append!(exprs,constructors)
        end
    end

    if print_summary
        printstyled("Generated ",imported," structs out of ",length(s),"\n";color=:green)
    end

    struct_skiplist, loaded
end

function all_struct_methods!(exprs,ns;print_summary=true,print_detailed=false,skiplist=Symbol[], struct_skiplist=Symbol[], liboverride=nothing)
    structs=get_structs(ns)
    handled_symbols=Symbol[]

    not_implemented=0
    skipped=0
    created=0
    for s in structs
        name=get_name(s)
        methods=get_methods(s)
        if in(name,struct_skiplist)
            skipped+=length(methods)
            continue
        end
        if print_detailed
            printstyled(name,"\n";bold=true)
        end
        for m in methods
            if in(get_name(m),skiplist)
                skipped+=1
                continue
            end
            flags = get_flags(m)
            if flags & (GIFunction.IS_CONSTRUCTOR | GIFunction.IS_METHOD) == 0
                continue
            end
            if is_deprecated(m)
                continue
            end
            if print_detailed
                println(get_name(m))
            end
            fun=create_method(m, liboverride)
            push!(exprs, fun)
            push!(handled_symbols,get_symbol(m))
            created+=1
        end
    end

    if print_summary
        printstyled(created, " struct methods created\n";color=:green)
        if skipped>0
            printstyled(skipped," struct methods skipped\n";color=:yellow)
        end
        if not_implemented>0
            printstyled(not_implemented," struct methods not implemented\n";color=:red)
        end
    end
    handled_symbols
end

function all_objects!(exprs,exports,ns;print_summary=true,handled=Symbol[],skiplist=Symbol[],constructor_skiplist=[],output_cache_define=true,output_cache_init=true)
    objects=get_all(ns,GIObjectInfo)

    imported=length(objects)
    loaded=Symbol[]
    # precompilation prevents adding directly to GLib's gtype_wrapper cache here
    # so we add to a package local cache and merge with GLib's cache in __init__()
    if output_cache_define
        gtype_cache = quote
            gtype_wrapper_cache = Dict{Symbol, Type}()
        end
        push!(exprs,unblock(gtype_cache))
    end
    for o in objects
        name=get_name(o)
        if name==:Object
            imported -= 1
            continue
        end
        if in(name, skiplist)
            imported -= 1
            continue
        end
        type_init = get_type_init(o)
        if type_init==:intern  # GParamSpec and children output this
            continue
        end
        obj_decl!(exprs,o,ns,handled)
        push!(exports.args, get_full_name(o))
        push!(loaded, name)
    end
    if output_cache_init
        gtype_cache_init = quote
            gtype_wrapper_cache_init() = merge!(GLib.gtype_wrappers,gtype_wrapper_cache)
        end
        push!(exprs,gtype_cache_init)
    end
    for o in objects
        if in(get_name(o), skiplist)
            continue
        end
        constructors = get_constructors(o;skiplist=constructor_skiplist, struct_skiplist=skiplist)
        if !isempty(constructors)
            append!(exprs,constructors)
        end
    end
    if print_summary
        printstyled("Created ",imported," objects out of ",length(objects),"\n";color=:green)
    end
    loaded
end

function all_object_methods!(exprs,ns;skiplist=Symbol[],object_skiplist=Symbol[], liboverride=nothing)
    not_implemented=0
    skipped=0
    created=0
    objects=get_all(ns,GIObjectInfo)
    for o in objects
        name=get_name(o)
        methods=get_methods(o)
        if in(name,object_skiplist)
            skipped+=length(methods)
            continue
        end
        for m in methods
            if in(get_name(m),skiplist)
                skipped+=1
                continue
            end
            if is_deprecated(m)
                continue
            end
            try
                fun=create_method(m, liboverride)
                push!(exprs, fun)
                created+=1
            catch NotImplementedError
                println("$name method not implemented: ",get_name(m))
                not_implemented+=1
            end
        end
    end
end

function all_interfaces!(exprs,exports,ns;print_summary=true,skiplist=Symbol[])
    interfaces=get_all(ns,GIInterfaceInfo)

    imported=length(interfaces)
    for i in interfaces
        name=get_name(i)
        # could use the following to narrow the type
        #p=get_prerequisites(i)
        #type_init = get_type_init(i)
        if in(name,skiplist)
            imported-=1
            continue
        end
        push!(exprs,decl(i))
        push!(exports.args, get_full_name(i))
    end

    if print_summary && imported>0
        printstyled("Created ",imported," interfaces out of ",length(interfaces),"\n";color=:green)
    end
    skiplist
end

function all_interface_methods!(exprs,ns;skiplist=Symbol[],interface_skiplist=Symbol[], liboverride=nothing)
    not_implemented=0
    skipped=0
    created=0
    interfaces=get_all(ns,GIInterfaceInfo)
    for i in interfaces
        name=get_name(i)
        methods=get_methods(i)
        if in(name,interface_skiplist)
            skipped+=length(methods)
            continue
        end
        for m in methods
            if in(get_name(m),skiplist)
                skipped+=1
                continue
            end
            if is_deprecated(m)
                continue
            end
            try
                fun=create_method(m, liboverride)
                push!(exprs, fun)
                created+=1
            catch NotImplementedError
                println("$name method not implemented: ",get_name(m))
                not_implemented+=1
            end
        end
    end
end

function all_functions!(exprs,ns;print_summary=true,skiplist=Symbol[],symbol_skiplist=Symbol[], liboverride=nothing)
    j=0
    skipped=0
    not_implemented=0
    for i in get_all(ns,GIFunctionInfo)
        if in(get_name(i),skiplist) || occursin("cclosure",string(get_name(i)))
            skipped+=1
            continue
        end
        if in(get_symbol(i),symbol_skiplist) # quietly drop methods already handled
            continue
        end
        unsupported = false # whatever we happen to unsupport
        for arg in get_args(i)
            try
                bt = get_base_type(get_type(arg))
                if isa(bt,Ptr{GIArrayType}) || isa(bt,Ptr{GIArrayType{3}})
                    unsupported = true; break
                end
                if (isa(get_base_type(get_type(arg)), Nothing))
                    unsupported = true; break
                end
            catch NotImplementedError
                continue
            end
        end
        try
            bt = get_base_type(get_return_type(i))
            if isa(bt,Symbol)
                unsupported = true;
            end
            if unsupported
                skipped+=1
                continue
            end
        catch NotImplementedError
            continue
        end
        name = get_name(i)
        name = Symbol("$name")
        try
            fun=create_method(i, liboverride)
            push!(exprs, fun)
            j+=1
        catch NotImplementedError
            println("Function not implemented: ",name)
            not_implemented+=1
            continue
        end
        #push!(exports.args, name)
    end

    if print_summary
        printstyled("created ",j," functions\n";color=:green)
        if skipped>0
            printstyled("skipped ",skipped," out of ",j+skipped," functions\n";color=:yellow)
        end
        if not_implemented>0
            printstyled(not_implemented," functions not implemented\n";color=:red)
        end
    end
end

function write_to_file(filename,toplevel)
    open(filename,"w") do f
        Base.println(f,"quote")
        Base.remove_linenums!(toplevel)
        Base.show_unquoted(f, toplevel)
        println(f)
        Base.println(f,"end")
    end
end

write_to_file(path,filename,toplevel)=write_to_file(joinpath(path,filename),toplevel)

function output_exprs()
    body = Expr(:block)
    toplevel = Expr(:toplevel, body)
    exprs = body.args
    exports = Expr(:export)
    toplevel, exprs, exports
end

# Read from XML
isdisguised(c) = haskey(c,"disguised") && (c["disguised"] == "1")

function read_disguised(d)
    r = d.root
    isnothing(r) && return Symbol[]
    ns=EzXML.namespace(r)
    all_recs=findall("//x:namespace/x:record",r, ["x"=>ns])
    n=findall(isdisguised,all_recs)
    [Symbol(ni["name"]) for ni in all_recs[n]]
end
