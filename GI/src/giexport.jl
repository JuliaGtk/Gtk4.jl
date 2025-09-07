# functions that output expressions for a library in bulk

## Constants, enums, and flags
function _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded, export_constants = true)
    for e in es
        name = Symbol(get_name(e))
        in(name, skiplist) && continue
        push!(const_mod.args, unblock(decl(e,incl_typeinit)))
        export_constants && push!(const_exports.args, name)
        push!(loaded,name)
    end
end

function all_const_exprs!(const_mod, const_exports, ns;print_summary=true,incl_typeinit=true,skiplist=Symbol[], export_constants = true, exclude_deprecated = true)
    loaded=Symbol[]
    c = get_consts(ns, exclude_deprecated)

    for (name,val) in c
        in(name, skiplist) && continue
        push!(const_mod.args, const_expr("$name",val))
        push!(loaded,name)
    end
    if print_summary && length(c)>0
        printstyled("Generated ",length(c)," constants\n";color=:green)
    end

    es=get_all(ns,GIEnumInfo,exclude_deprecated)
    _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded, export_constants)

    if print_summary && length(es)>0
        printstyled("Generated ",length(es)," enums\n";color=:green)
    end

    es=get_all(ns,GIFlagsInfo,exclude_deprecated)
    _enums_and_flags(es, skiplist, incl_typeinit, const_mod, const_exports, loaded, export_constants)

    if print_summary && length(es)>0
        printstyled("Generated ",length(es)," flags\n";color=:green)
    end
    loaded
end

function export_consts!(ns,path,prefix,skiplist = Symbol[]; doc_prefix = prefix, doc_xml = nothing, export_constants = true, exclude_deprecated = true)
    toplevel, exprs, exports = GI.output_exprs()

    const_mod = Expr(:block)

    c = all_const_exprs!(const_mod, exports, ns; skiplist= skiplist, export_constants, exclude_deprecated)
    if doc_xml !== nothing
        GI.append_const_docs!(const_mod.args, doc_prefix, doc_xml, c)
    end
    isempty(exports.args) || push!(const_mod.args, exports)

    push!(exprs, MacroTools.flatten(const_mod))

    ## export constants, enums, and flags code
    GI.write_consts_to_file(path,"$(prefix)_consts",toplevel)
end

## Structs

function struct_cache_expr!(exprs)
    gboxed_types_list = quote
        const gboxed_types = Any[]
    end
    push!(exprs,unblock(gboxed_types_list))
end

function get_non_skipped(ns, t, skiplist, exclude_deprecated)
    l=get_all(ns,t,exclude_deprecated)
    filter!(l) do o
        !in(get_name(o), skiplist)
    end
    l
end

function struct_exprs!(exprs,exports,ns,structs=nothing;print_summary=true,excludelist=[],constructor_skiplist=[],import_as_opaque=[],output_cache_init=true,only_opaque=false,exclude_deprecated=true)
    struct_skiplist=excludelist

    if structs === nothing
        s=get_non_skipped(ns,GIStructInfo,struct_skiplist,exclude_deprecated)
        structs = get_name.(s)
    end

    imported=length(structs)
    for ss in structs
        ssi=gi_find_by_name(ns,ss)
        name=Symbol(get_name(ssi))
        fields=get_fields(ssi)
        if only_opaque && length(fields)>0 && !in(name,import_as_opaque)
            imported-=1
            push!(struct_skiplist,name)
            continue
        end
        if occursin("Private",String(name))
            imported-=1
            push!(struct_skiplist,name)
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
        catch e
            if isa(e, NotImplementedError)
                if print_summary
                    printstyled(name," not implemented\n";color=:red)
                end
                push!(struct_skiplist,name)
                imported-=1
                continue
            else
                rethrow(e)
            end
        end
        push!(exports.args, get_full_name(ssi))
        length(fields)>0 && push!(exports.args,get_struct_name(ssi,false))
        if length(fields)>0 && !in(name, import_as_opaque)
            push!(exports.args, structptrlike(ssi))
        end
    end

    if print_summary
        printstyled("Generated ",imported," structs out of ",length(structs),"\n";color=:green)
    end

    struct_skiplist
end

function struct_constructor_exprs!(exprs,ns;constructor_skiplist=[], struct_skiplist=[], exclude_deprecated=true,first_list=[])
    s=get_non_skipped(ns,GIStructInfo,struct_skiplist,exclude_deprecated)
    for ss in vcat(first_list, get_name.(s))
        ssi=gi_find_by_name(ns,ss)
        constructors = get_constructors(ssi;skiplist=constructor_skiplist, struct_skiplist=struct_skiplist, exclude_deprecated=exclude_deprecated)
        append!(exprs,constructors)
    end
end

function all_struct_exprs!(exprs,exports,ns;print_summary=true,excludelist=[],constructor_skiplist=[],import_as_opaque=Symbol[],output_cache_init=true,only_opaque=false,exclude_deprecated=true)
    struct_skiplist=excludelist
    loaded=Symbol[]

    ss=get_non_skipped(ns,GIStructInfo,struct_skiplist,exclude_deprecated)
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
        if length(fields)>0
            push!(exports.args, structptrlike(ssi))
        end
        push!(loaded, name)
        length(fields)>0 && push!(exports.args,get_struct_name(ssi,false))
    end

    if output_cache_init
        gboxed_types_init = quote
            gboxed_cache_init() = append!(GLib.gboxed_types,gboxed_types)
        end
        push!(exprs,unblock(gboxed_types_init))
    end

    if print_summary
        printstyled("Generated ",imported," structs out of ",length(ss),"\n";color=:green)
    end

    struct_skiplist, loaded
end

function all_callbacks!(exprs, exports, ns; callback_skiplist = [], exclude_deprecated = true)
    for c in get_all(ns,GICallbackInfo,exclude_deprecated)
        get_name(c) in callback_skiplist && continue
        try
            push!(exprs, decl(c))
        catch e
            if isa(e, NotImplementedError)
                continue
            else
                rethrow(e)
            end
        end
        push!(exports.args, get_full_name(c))
    end
    nothing
end

function export_struct_exprs!(ns,path,prefix, struct_skiplist, import_as_opaque; doc_xml = nothing, doc_prefix = prefix, constructor_skiplist = [], first_list = [], output_boxed_cache_init = true, output_object_cache_init = true, output_object_cache_define = true, object_skiplist = [], object_constructor_skiplist = [], interface_skiplist = [], signal_skiplist = [], expr_init = nothing, output_gtype_wrapper_cache_def = false, output_boxed_types_def = true, output_callbacks = true, exclude_deprecated = true, doc_skiplist = [], callback_skiplist = [])
    toplevel, exprs, exports = GI.output_exprs()

    if output_boxed_types_def
        struct_cache_expr!(exprs)
    end

    if !isempty(first_list)
        GI.struct_exprs!(exprs,exports,ns,first_list)
        struct_skiplist = vcat(struct_skiplist,first_list)
    end
    struct_skiplist, c = all_struct_exprs!(exprs,exports,ns;constructor_skiplist=constructor_skiplist,excludelist=struct_skiplist,import_as_opaque=import_as_opaque, output_cache_init = output_boxed_cache_init, exclude_deprecated=exclude_deprecated)
    if doc_xml !== nothing
        append_struc_docs!(exprs, doc_prefix, doc_xml, c, ns)
    end
    all_interfaces!(exprs,exports,ns; skiplist = interface_skiplist, exclude_deprecated = exclude_deprecated)
    c = all_objects!(exprs,exports,ns;handled=[:Object],skiplist=object_skiplist,output_cache_init = output_object_cache_init, output_cache_define = output_object_cache_define, constructor_skiplist = object_constructor_skiplist,exclude_deprecated=exclude_deprecated)
    struct_constructor_exprs!(exprs,ns;constructor_skiplist=constructor_skiplist,exclude_deprecated=exclude_deprecated,struct_skiplist=struct_skiplist,first_list=first_list)
    if doc_xml !== nothing
        append_object_docs!(exprs, doc_prefix, doc_xml, c, ns; skiplist = doc_skiplist)
    end
    if expr_init !== nothing
        push!(exprs,expr_init)
    end
    all_object_signals!(exprs, ns;skiplist=signal_skiplist,object_skiplist=object_skiplist, exclude_deprecated = exclude_deprecated)
    if output_callbacks
        all_callbacks!(exprs, exports, ns; callback_skiplist, exclude_deprecated)
    end
    push!(exprs,exports)
    write_to_file(path,"$(prefix)_structs",toplevel)
    struct_skiplist
end

function all_struct_methods!(exprs,ns;print_summary=true,print_detailed=false,skiplist=Symbol[], struct_skiplist=Symbol[], liboverride=nothing,exclude_deprecated=true)
    structs=get_structs(ns,exclude_deprecated)
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
        print_detailed && printstyled(name,"\n";bold=true)
        for m in methods
            if in(get_name(m),skiplist)
                skipped+=1
                continue
            end
            if get_flags(m) & (GIFunction.IS_CONSTRUCTOR | GIFunction.IS_METHOD) == 0
                continue
            end
            (exclude_deprecated && is_deprecated(m)) && continue
            print_detailed && println(get_name(m))
            try
                create_method(exprs, m, liboverride)
                push!(handled_symbols,get_symbol(m))
                created+=1
            catch e
                if isa(e, NotImplementedError)
                    continue
                else
                    error("Error: $name.$(get_name(m))")
                    rethrow(e)
                end
            end
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

function all_objects!(exprs,exports,ns;print_summary=true,handled=Symbol[],skiplist=Symbol[],constructor_skiplist=[],output_cache_define=true,output_cache_init=true, exclude_deprecated=true)
    objects=get_non_skipped(ns,GIObjectInfo,skiplist,exclude_deprecated)

    imported=length(objects)
    loaded=Symbol[]
    # precompilation prevents adding directly to GLib's gtype_wrapper cache here
    # so we add to a package local cache and merge with GLib's cache in __init__()
    if output_cache_define
        gtype_cache = quote
            const gtype_wrapper_cache = Dict{Symbol, Type}()
        end
        push!(exprs,unblock(gtype_cache))
    end
    for o in objects
        name=get_name(o)
        if name==:Object
            imported -= 1
            continue
        end
        if get_type_init_function_name(o)==:intern  # GParamSpec and children output this
            continue
        end
        obj_decl!(exprs,o,ns,handled)
        push!(exports.args, get_full_name(o))
        if !get_abstract(o)
            push!(exports.args, Symbol(get_full_name(o),"Leaf"))
        end
        push!(loaded, name)
    end
    if output_cache_init
        gtype_cache_init = quote
            gtype_wrapper_cache_init() = merge!(GLib.gtype_wrappers,gtype_wrapper_cache)
        end
        push!(exprs,gtype_cache_init)
    end
    for o in objects
        constructors = get_constructors(o;skiplist=constructor_skiplist, struct_skiplist=skiplist, exclude_deprecated=exclude_deprecated)
        append!(exprs,constructors)
    end
    if print_summary
        printstyled("Created ",imported," objects out of ",length(objects),"\n";color=:green)
    end
    loaded
end

function all_object_methods!(exprs,ns;skiplist=Symbol[],object_skiplist=Symbol[], liboverride=nothing, exclude_deprecated=true, interface_helpers=true)
    not_implemented=0
    skipped=0
    created=0
    for o in get_non_skipped(ns,GIObjectInfo,object_skiplist,exclude_deprecated)
        name=get_name(o)
        methods=get_methods(o)
        for m in methods
            if in(get_name(m),skiplist)
                skipped+=1
                continue
            end
            (exclude_deprecated && is_deprecated(m)) && continue
            try
                create_method(exprs, m, liboverride)
                created+=1
            catch e
                if isa(e, NotImplementedError)
                    printstyled("$name method $(get_name(m)) not implemented: ",e.message,"\n"; color=:red)
                    not_implemented+=1
                else
                    error("Error: $name, $(get_name(m))")
                    rethrow(e)
                end
            end
        end
        if interface_helpers
            for i in get_interfaces(o)
                printstyled("$(get_name(i))\n"; color=:blue)
                for m in get_methods(i)
                    printstyled("$(get_name(m))\n"; color=:green)
                    fun = create_interface_method(m, o, liboverride)
                    fun !== nothing && push!(exprs, fun)
                end
            end
        end
    end
end

function all_object_signals!(exprs,ns;skiplist=Symbol[],object_skiplist=Symbol[], liboverride=nothing, exclude_deprecated=true)
    not_implemented=0
    for o in get_non_skipped(ns,GIObjectInfo,object_skiplist,exclude_deprecated)
        signals = get_all_signals(o)
        for s in signals
            (exclude_deprecated && is_deprecated(s)) && continue
            push!(exprs, decl(s,o))
        end
    end
end

function all_interfaces!(exprs,exports,ns;print_summary=true,skiplist=Symbol[],exclude_deprecated=true)
    interfaces=get_non_skipped(ns,GIInterfaceInfo,skiplist,exclude_deprecated)

    for i in interfaces
        # could use the following to narrow the type
        #p=get_prerequisites(i)
        #type_init = get_type_init(i)
        push!(exprs,decl(i))
        push!(exports.args, get_full_name(i))
    end

    if print_summary && length(interfaces)>0
        printstyled("Created ",length(interfaces)," interfaces\n";color=:green)
    end
    skiplist
end

function all_interface_methods!(exprs,ns;skiplist=Symbol[],interface_skiplist=Symbol[], liboverride=nothing,exclude_deprecated=true)
    not_implemented=0
    created=0
    interfaces=get_non_skipped(ns,GIInterfaceInfo,interface_skiplist,exclude_deprecated)
    for i in interfaces
        name=get_name(i)
        methods=get_methods(i)
        for m in methods
            if in(get_name(m),skiplist)
                continue
            end
            (exclude_deprecated && is_deprecated(m)) && continue
            try
                create_method(exprs, m, liboverride)
                created+=1
            catch e
                if isa(e, NotImplementedError)
                    println("$name method not implemented: ",get_name(m))
                    not_implemented+=1
                else
                    rethrow(e)
                end
            end
        end
    end
end

function export_methods!(ns,path,prefix;struct_method_skiplist = Symbol[], object_method_skiplist = Symbol[],interface_method_skiplist = Symbol[], struct_skiplist = Symbol[], interface_skiplist = Symbol[], object_skiplist = Symbol[], exclude_deprecated = true, interface_helpers = true)
    toplevel, exprs, exports = GI.output_exprs()

    all_struct_methods!(exprs,ns, struct_skiplist = struct_skiplist, skiplist = struct_method_skiplist, exclude_deprecated = exclude_deprecated)
    all_object_methods!(exprs,ns; skiplist = object_method_skiplist, object_skiplist = object_skiplist, exclude_deprecated = exclude_deprecated, interface_helpers)
    all_interface_methods!(exprs,ns; skiplist = interface_method_skiplist, interface_skiplist = interface_skiplist, exclude_deprecated = exclude_deprecated)

    write_to_file(path,"$(prefix)_methods",toplevel)
end

function all_functions!(exprs,ns;print_summary=true,skiplist=Symbol[],symbol_skiplist=Symbol[], liboverride=nothing,exclude_deprecated=true)
    j=0
    skipped=0
    not_implemented=0
    for i in get_non_skipped(ns,GIFunctionInfo,skiplist,exclude_deprecated)
        if occursin("cclosure",string(get_name(i)))
            continue
        end
        if in(get_symbol(i),symbol_skiplist) # quietly drop methods already handled
            continue
        end
        unsupported = false # whatever we happen to unsupport
        for arg in get_args(i)
            try
                bt = get_base_type(get_type_info(arg))
                if isa(bt,Ptr{GIArrayType}) || isa(bt,Ptr{GIArrayType{3}})
                    unsupported = true; break
                end
                if (isa(get_base_type(get_type_info(arg)), Nothing))
                    unsupported = true; break
                end
            catch e
                if isa(e, NotImplementedError)
                    continue
                else
                    rethrow(e)
                end
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
        catch e
            if isa(e, NotImplementedError)
                continue
            else
                rethrow(e)
            end
        end
        name = get_name(i)
        name = Symbol("$name")
        try
            create_method(exprs, i, liboverride)
            j+=1
        catch e
            if isa(e, NotImplementedError)
                printstyled("Function $name not implemented: ",e.message,"\n"; color=:red)
                not_implemented+=1
                continue
            else
                println("Error: $name")
                rethrow(e)
            end
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

function export_functions!(ns,path,prefix;skiplist = Symbol[], exclude_deprecated = true)
    toplevel, exprs, exports = GI.output_exprs()
    all_functions!(exprs,ns; skiplist = skiplist, exclude_deprecated = exclude_deprecated)
    write_to_file(path,"$(prefix)_functions",toplevel)
end

function write_to_file(filename,block)
    open(filename,"w") do f
        Base.remove_linenums!(block)
        Base.show_unquoted(f, MacroTools.flatten(block))
        println(f)
    end
end

write_to_file(path,filename,toplevel)=write_to_file(joinpath(path,filename),toplevel)

function write_consts_to_file(filename,block)
    open(filename,"w") do f
        Base.remove_linenums!(block)
        for expr in MacroTools.flatten(block).args
            Base.show_unquoted(f, expr)
            println(f)
        end
    end
end

write_consts_to_file(path,filename,toplevel)=write_consts_to_file(joinpath(path,filename),toplevel)

function output_exprs()
    block = Expr(:block)
    exprs = block.args
    exports = Expr(:export)
    block, exprs, exports
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
