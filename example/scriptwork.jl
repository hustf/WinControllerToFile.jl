
using WinControllerToFile
hids = hid_dict()
hidvec = hid_vector()
hidvec[1]
h = hids["\\\\?\\hid#vid_044f&pid_b10a#6&396faf92&0&0000#{4d1e55b2-f16f-11cf-88cb-001111000030}"] 
set_raw_data_handler(1, h)
open_hid(h)
is_plugged(h)
subscribe()
POLLINGTASKS
rt = POLLINGTASKS[1]
chnl= Channel(1)
bind(chnl, rt)
yield()
# Define a task for throwing interrupt exception to the (possibly blocked) read task.
# We don't start this task because it would never return
killta = @task try
    throwto(rt, InterruptException())
catch
end
# We start the killing task. When it is scheduled the second time,
# we pass an InterruptException through the scheduler.
try
    schedule(killta, InterruptException(), error = false)
catch
end
# We now possibly have content on chnl, and no additional tasks.
if isready(chnl)
    take!(chnl)
end
rt
