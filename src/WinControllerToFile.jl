"Call hid_vector() or hid_dict() to get references to human interface devices"
module WinControllerToFile
using PyCall
export PyObject, Hid, hid_dict, hid_vector
export set_data_handler
export subscribe, ACTIVE_SUBSCRIPTIONS, POLLINGTASKS
import Base.show

"""
A vector of strings, defined by user generated file names in ~/.julia_hid
Each string corresponds to a Hid.device_path.
Its index in SUBSCRIBETO is part of the name of a python handler function we 
defined during this module's initialization.

SUBSCRIBETO is populated during this module's initialization. The
simplest way to add a subscription may be to exit Julia, make the files 
and exit.
"""

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
Define subscriptions and start polling. 
Polling continues asyncronously until this process is terminated.
"""
function subscribe()
    hids = hid_dict()
    nohid = Hid()
    local count = 0
    for (i, su) in enumerate(SUBSCRIBETO)
        h = get(hids, su, nohid)
        fina = joinpath(homedir(), ".julia_hid", su * ".txt")
        if h == nohid
            @warn("The file $fina \n\t does not correspond to a connected Human Interface Device")
        else
            count += 1
            set_data_handler(i, h)
            open_hid(h)
            push!(ACTIVE_SUBSCRIPTIONS, h)
            task = @async poller(ΔT, h)
            push!(POLLINGTASKS, task)
            @info "Updating $fina \n\t at $(Int(floor(1/ΔT)))) Hz for $MAXTIME s"
        end
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
        if length(filenames) == 0
            @info "You need to make a *.txt file in $fo"
        else
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
                def sample_handler$$i(data):
                    with open($$fina, 'w') as f:
                        f.write("Raw data: {0}".format(data))
                """
            end
            @info("Generated $i Python handlers, run subscribe() when ready")
        end
    else
        @info("You need to create folder $fo")
    end
end

end # module
