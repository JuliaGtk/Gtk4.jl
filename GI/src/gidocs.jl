# extracting documentation strings from .gir XML files

function read_gir(m::Module, ns::GINamespace)
    d = m.find_artifact_dir()*"/share/gir-1.0/$(GI.ns_id(ns)).gir"
    !isa(d,String) && error("Can't find GIR")
    EzXML.readxml(d)
end

function append_doc!(exprs, docstring, name)
    push!(exprs, Expr(:macrocall, Symbol("@doc"), nothing, docstring, name))
end

function doc_add_link(docstring, l)
    # FIXME: should escape the string in the square brackets because the underscores mess up the markdown formatting
    "$docstring\n \nDetails can be found in the [GTK docs]($l)."
end

_name_match(n, name)=n["name"]==String(name)

function doc_item(d, name, t)
    r = d.root
    r === nothing && return nothing
    ns=EzXML.namespace(r)
    all_items=findall("//x:namespace/x:$t",r, ["x"=>ns])::Vector{EzXML.Node}
    n=findfirst(Base.Fix2(_name_match, name),all_items)
    if n !== nothing
        for e in eachelement(all_items[n])
            if e.name == "doc"
                lines=split(e.content,"\n\n")
                if length(lines)>1
                    return lines[1] # just pull the first chunk: a brief summary
                else
                    return e.content
                end
            end
        end
    end
    return nothing
    end

for (item, xmlitem) in [
    (:const, "constant"), (:enum, "enumeration"), (:flags, "bitfield"),
    (:struc, "record"), (:object, "class")]
    @eval function $(Symbol("doc_$(item)"))(d, name)
        doc_item(d, name, $xmlitem)
    end
    @eval function $(Symbol("doc_$(item)_add_link"))(docstring, name, nsstring)
        doc_add_link(docstring, $(Symbol("gtkdoc_$(item)_url"))(nsstring, name))
    end
end

function append_const_docs!(exprs, ns, d, c)
    for x in c
        dc = GI.doc_const(d,x)
        if dc !== nothing
            dc = GI.doc_const_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
    for x in c
        dc = GI.doc_enum(d,x)
        if dc !== nothing
            dc = GI.doc_enum_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
    for x in c
        dc = GI.doc_flags(d,x)
        if dc !== nothing
            dc = GI.doc_flags_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
end

function append_struc_docs!(exprs, ns, d, c, gins)
    for x in c
        dc = GI.doc_struc(d,x)
        if dc !== nothing
            dc = GI.doc_struc_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, get_full_name(gins[x]))
        end
    end
end

function append_object_docs!(exprs, ns, d, c, gins)
    for x in c
        dc = GI.doc_object(d,x)
        if dc !== nothing
            dc = GI.doc_object_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, get_full_name(gins[x]))
        end
    end
end
