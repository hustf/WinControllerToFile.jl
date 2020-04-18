using WinControllerToFile
subscribe()
hids = hid_dict()
keys(hids)
h = hids["hidvid_256fpid_c62e62476a257000004d1e55b2f16f11cf88cb001111000030"]
hidvec = hid_vector()
h = hidvec[1]
WinControllerToFile.documentation(stderr, h)


import WinControllerToFile.open_hid

open_hid(h)
import WinControllerToFile.is_plugged
is_plugged(h)

import WinControllerToFile.PyCall
import WinControllerToFile.pyimport

pyhid = pyimport("pywinusb.hid")
device = h.object

reps = h.object.find_input_reports()
rep1 = reps[1]
rep1_1 = pycall("rep1.get(1)")
rep1.get_raw_data()
kys = rep.keys()


rd=rep.get_raw_data()
subscribe()
POLLINGTASKS



set_data_handler(1, h)

device = h.object
device.find_output_reports()
device.find_feature_reports()
device.find_input_reports()
reps = device.find_any_reports()
device.find_input_usage()
device.get_physical_descriptor()
device.is_active()
device._process_raw_report(2)
device.HidReport
device.get_full_usage_id(0xff00, 0x02)

device.get()
get_hid_object()
get_raw_data()
get_usages()
has_key()
items()
keys()
send()
set_raw_data()
values()
_HidReport__alloc_raw_data()
_HidReport__prepare_raw_data()
__class__()
__contains__()
__delattr__()
__dir__()
__eq__()
__format__
__ge__
__getattribute__
__getitem__ 
__gt____hash__ 
__init__ 
__init_subclass__ 
__le__
__len__ 
__lt__
__ne__
__new__
__reduce__
__reduce_ex__
__repr__
__setattr__
__setitem__
__sizeof__
__str__
__subclasshook__
