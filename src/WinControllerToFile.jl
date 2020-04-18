"Call hid_vector() or hid_dict() to get references to human interface devices"
module WinControllerToFile
using PyCall
export Hid, hid_dict, hid_vector
export documentation
export subscribe
import Base.show

struct Hid
    vendor_name::String
    vID::Int64
    pID::Int64
    device_path::String
    version_number::Int
    product_name::String
    object::PyObject
end
Hid() = Hid("", 0, 0, "", 0, "", PyObject(1) )
include("show_device.jl")

const SUBSCRIBETO = Array{String, 1}()
const ACTIVE_SUBSCRIPTIONS = Array{Hid, 1}()
const POLLINGTASKS = Array{Task, 1}()
const ΔT = 0.02
const MAXTIME = 1800 # Half an hour


"Return a dictionary of usb human interface device references"
function hid_dict()
    pyhid = pyimport("pywinusb.hid")
    py_all_hids = pyhid.find_all_hid_devices()
    dic = Dict{String, Hid}()
    for h in py_all_hids
        pth = replace(h.device_path, r"[^a-zA-Z0-9_]" =>"")
        juhid = Hid(h.vendor_name,
            h.vendor_id,
            h.product_id,
            pth,
            h.version_number,
            h.product_name,
            h)
        nam = juhid.device_path
        push!(dic, nam => juhid)
    end
    dic
end

"Return a vector of usb human interface device references"
function hid_vector()
    collect(values(hid_dict()))
end

"Show full documentation for a device"
function documentation(io, h::Hid)
    pyhid = pyimport("pywinusb.hid")
    pyhid.core.show_hids(h.vID, h.pID, output = io)
    println(io, "\n\n")
    println(io, "Julia structure for device:")
    show(io, h)
    println(io, "\n\n")
    show(io, MIME("text/plain"), h)
end


open_hid(h::Hid) = h.object.open()
is_plugged(h::Hid) = h.object.is_plugged()
set_data_handler(i, h::Hid) = h.object.set_raw_data_handler(py"sample_handler$$i")




"The minimum Δt is 1 millisecond or 0.001. "
function poller(Δt, h::Hid)
    t0 = time()
    while time()-t0 < MAXTIME && is_plugged(h) # This triggers one sample written to file.
        sleep(Δt)
    end
    @info "Exit polling of  $(h.vendor_name) $(h.product_name) after $MAXTIME s "
end

"""
Define subscriptions and start reacting to events.
Subscriptions run asyncronously until this process is terminated,
although no events actually occur after MAXTIME.
"""
function subscribe()
    if length(ACTIVE_SUBSCRIPTIONS) !=0
        error("Sorry, you need to restart this module since subscriptions are defined.")
    end
    fo = joinpath(homedir(), ".julia_hid")
    docfo = joinpath(fo, "DocumentationFo")
    hids = hid_dict()
    nohid = Hid()
    local count = 0
    for (i, su) in enumerate(SUBSCRIBETO)
        h = get(hids, su, nohid)
        fina = joinpath(fo, su * ".txt")
        if h == nohid
            @warn("The file $fina \n\t does not correspond to a connected Human Interface Device")
        else
            count += 1
            set_data_handler(i, h)
            open_hid(h)
            push!(ACTIVE_SUBSCRIPTIONS, h)
            task = @async poller(ΔT, h)
            push!(POLLINGTASKS, task)
        end
        # Also write the full documentation for the subscribed device as a file
        docfina = joinpath(docfo, su * ".txt")
        @info "Writing documentation to $docfo"
        open(docfina, write=true) do io
            documentation(io, h)
        end
        @info "Updating $fina \n\t at $(Int(floor(1/ΔT)))) Hz for $MAXTIME s"
    end
    if count == 0
        @info """
                Available hids
            """
        display(hids)
        filenames= map(collect(keys(hids))) do ke
            ke * ".txt"
        end
        @info "Candidates, create empty files  in '$(joinpath(homedir(), ".julia_hid"))':"
        display(filenames)
    end
    nothing
end


function __init__()
    fo = joinpath(homedir(), ".julia_hid")
    if ispath(fo)
        filenames = filter(isfile, readdir(fo, join=true))
        if length(filenames) != 0
            docfo = joinpath(fo, "DocumentationFo")
            if ispath(docfo)
                local i = 0
                for fi in filenames
                    i += 1
                    subscription = replace(splitpath(fi)[end], ".txt" => "")
                    push!(SUBSCRIBETO, subscription)
                    # File name string enclosed by '"' and using forward slash
                    fina = "\"" * replace(fi, "\\" => "/") * "\""

                    # Define a Python handler for this object.
                    # The handler function name includes sequence 'i',
                    # so that we can handle multiple controllers.
                    py"""
                    import time
                    def sample_handler$$i(data):
                        i = 1
                        headline = "#"
                        dataline = " "
                        for el in data:
                            headline +="chn{:<5d}".format(i)
                            dataline += "{:<8d}".format(el)
                            i +=1
                        timeline = "{} : Current time value".format(time.time())
                        lines = headline + "\n" + dataline + "\n" + timeline
                        with open($$fina, 'w') as f:
                            f.write(lines)"""
                end
                @info("Generated $i Python handlers, run subscribe() when ready")
            else
                @warn("You need to create folder $docfo\n\tThen recompile WinControllerToFile")
            end
        else
            @warn "You need to make a X.txt file in $fo\n\twhere 'X' represents the device(s) you will subscribe to.\n\tThen recompile WinControllerToFile"
        end
    else
        @warn("You need to create folder $fo\n\tThen recompile WinControllerToFile")
    end
end

end # module
