import Base.show
function name(h::Hid)
    iob = IOBuffer()
    print(iob, h.vendor_name, " ")
    print(iob, h.product_name)
    print(iob, "(vID=0x", string(h.vID, base=16), ", ")
    print(iob, "pID=0x", string(h.pID, base=16), ")")
    String(take!(iob))
end

# Long form, as in display(h) or REPL: h enter
function Base.show(io::IO, ::MIME"text/plain", h::Hid)
    ioc = IOContext(io)
    print(ioc, "Hid(")
    print(ioc, "\tvendor_name:\t ", h.vendor_name, "\n")
    print(ioc, "\tproduct_name: ", h.product_name, "\n")
    print(ioc, "\tvID:\t 0x", string(h.vID, base=16), "\n")
    print(ioc, "\tpID:\t 0x", string(h.pID, base=16), "\n")
    print(ioc, "\tdevice_path:\t ", h.device_path, ")")
end


# Short form, as in print(stdout, h)
function Base.show(io::IO, h::Hid)
    ioc = IOContext(io)
    if get(ioc, :color, false)
        printstyled(ioc, h.vendor_name, color=:green, bold = false)
        print(ioc, " ")
        printstyled(ioc, h.product_name, color=:green, bold = true)
        print(ioc, "(vID=0x", string(h.vID, base=16), ", ")
        print(ioc, "pID=0x", string(h.pID, base=16), ")")
    else
        print(ioc, name(h))
    end
end

# The default Juno / Atom display works nicely with standard output
Base.show(io::IO, ::MIME"application/prs.juno.inline", hid::Hid) = Base.show(io, hid)

# Vector
function Base.show(io::IO, ::MIME"text/plain", hids::Array{Hid,1})
    print(io, length(hids), "-element ")
    println(io, typeof(hids), ":")
    for (i, h) in enumerate(hids)
        println(io, " [", i, "]\t", h)
    end
end