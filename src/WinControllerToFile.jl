"Call hid_vector() or hid_dict() to get references to human interface devices"
module WinControllerToFile
import REPL
using PyCall, REPL.TerminalMenus
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

"The minimum Δt is around 250 millisecond. The bottleneck seems to be PyWinUsb."
const ΔT = 0.25      # s
const TIMEOUT = 1800 # Half an hour


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




"The minimum Δt is around 250 millisecond. The bottleneck seems to be PyWinUsb."
function poller(timeout, Δt, h::Hid)
    t0 = time()
    while time()-t0 < timeout && is_plugged(h) # This triggers one sample written to file.
        # PyWinUsb tends to pile up threads. Not triggering too often may help avoiding that.
        sleep(Δt * 0.9)
    end
    @info "Exit polling of  $(h.vendor_name) $(h.product_name) after $timeout s "
end

"""
Define subscriptions and start reacting to events.
Subscriptions run asyncronously until this process is terminated,
although no events actually occur after timeout.
"""
function subscribe(;timeout = TIMEOUT, Δt = ΔT)
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
            task = @async poller(timeout, Δt, h)
            push!(POLLINGTASKS, task)
        end
        # Also write the full documentation for the subscribed device as a file
        docfina = joinpath(docfo, su * ".txt")
        @info "Writing documentation to $docfina"
        open(docfina, write=true) do io
            documentation(io, h)
        end
        println(stdout, h)
        @info "Updating $fina \n\t at $(Int(floor(1/Δt)))) Hz for $timeout s"
    end
    if count == 0
        @info "No subscription files X.txt found in $fo\n\t. "
        iob = IOBuffer()
        ioc = IOContext(iob, :color => true, :limit => false)
        show(ioc, "text/plain", values(hids))
        st=String(take!(iob))
        options = String.(split(st, "\n")[2:end])
        menu = MultiSelectMenu(options,  pagesize = length(options))
        choices = request("Select devices to subscribe to:", menu)
        vehids = collect(values(hids))
        for choice in choices
            device = vehids[choice]
            shfina = device.device_path * ".txt"
            fina = joinpath(fo, shfina)
            println(stdout, "\n", device, "\n\t\t\t\tStatus file ", shfina)
            open(fina, write = true) do io
                print(io, "\n")
            end
        end
        @info "Recompile WinControllerToFile to subscribe to updates based on connected devices and files in $fo"
    end
    POLLINGTASKS
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
                    t0 = time.time()
                    t$$i = time.time()

                    def sample_handler$$i(data):
                        global t0
                        global t$$i
                        if (time.time() - t$$i) >= $$ΔT:
                            j = 1
                            headline = "#"
                            dataline = " "
                            for el in data:
                                headline +="chn{:<5d}".format(j)
                                dataline += "{:<8d}".format(el)
                                j +=1
                            timeline = "{} : time".format(time.time() - t0)
                            lines = headline + "\n" + dataline + "\n" + timeline
                            with open($$fina, 'w') as f:
                                f.write(lines)

                            t$$i = time.time()"""

                end
                @info("Generated $i Python handlers, run subscribe() when ready")
            else
                @warn("You need to create folder $docfo\n\tThen recompile WinControllerToFile")
            end
        else
            @warn "No subscription files X.txt found in $fo\n\t. Run subscribe() to pick devices and generate the corresponding files. "
        end
    else
        @warn("You need to create folder $fo\n\tThen recompile WinControllerToFile")
    end
end

end # module
