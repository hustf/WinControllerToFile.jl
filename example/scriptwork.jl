
using WinControllerToFile
hids = hid_dict()
h = hids["\\\\?\\hid#vid_044f&pid_b10a#6&396faf92&0&0000#{4d1e55b2-f16f-11cf-88cb-001111000030}"] 
set_raw_data_handler(1, h)
open_hid(h)
is_plugged(h)
