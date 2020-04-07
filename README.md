# WinControllerToFile
This package polls [rene-aguirre/pywinusb](https://github.com/rene-aguirre/pywinusb/) through [PyCall](https://github.com/JuliaPy/PyCall.jl).

Use a mouse or spacemouse without depending on run-time state in your application! Keep it running in a separate process! It hopefully does not interfere with your other uses of these devices.

This package updates a separate file per subscribed device with current state. A time stamp for the last state change can be used for integration over time! 

## Installation
The default Python environment used by PyCall must include 'pywinusb'. One roundabout way to install that is:

```
julia > ]add Conda

julia> using Conda

julia> Conda.add("pywinusb", Conda.ROOTENV, channel = "conda-forge")

julia> add WinControllerToFile
```

You can locate the Python source using 
```
julia > using PyCall; pyimport("site").getsitepackages()
2-element Array{String,1}:
 "C:\\Users\\F\\.julia\\conda\\3"
 "C:\\Users\\F\\.julia\\conda\\3\\lib\\site-packages"
```

## Usage
```
julia> using WinControllerToFile
[ Info: Precompiling WinControllerToFile [35ccf8fc-7b30-4032-8229-e6f975734ee0]
[ Info: Generated 1 Python handlers, run subscribe() when ready

julia> subscribe()
[ Info: Updating hidvid_044fpid_b10a6396faf92000004d1e55b2f16f11cf88cb001111000030.txt at 50) Hz for 1800 s

julia> [ Info: Exit polling of  Thrustmaster T.16000M after 1800 s
julia>

julia> hid_dict()
Dict{String,Hid} with 13 entries:
  "hidvid_046dpid_c336mi_01col… => Logitech Gaming Keyboard G213(vID=…
  "hidvid_1532pid_006emi_01col… => Razer Razer DeathAdder Essential(v…
  "hidvid_1532pid_006emi_01col… => Razer Razer DeathAdder Essential(v…
  "hid3dxkmj_hidminicol0314784… => Unknown manufacturer @input.inf,%hid_devic…
  "hidvid_1532pid_006emi_01col… => Razer Razer DeathAdder Essential(v…
  "hidvid_044fpid_b10a6396faf9… => Thrustmaster T.16000M(vID=0x44f, p…
  "hidhidclasscol0112d595ca700… => Acer Inc. Launch Manager Wireless Deviceidhidclasscol0212d595ca700… => Acer Inc. Launch Manager Wireless Deviceidvid_046dpid_c336mi_01col… => Logitech Gaming Keyboard G213(vID=…
  "hidsyna7db5col03522d8713900… => Microsoft HIDI2C Device(vID=0x6cb,…
  "hidsyna7db5col04522d8713900… => Microsoft HIDI2C Device(vID=0x6cb,…
  "hidvid_046dpid_c336mi_01col… => Logitech Gaming Keyboard G213(vID=…
  "hidvid_1532pid_006emi_01col… => Razer Razer DeathAdder Essential(v…

julia>
PS C:\> cd ~\.julia_hid
PS C:\Users\F\.julia_hid>PS C:\Users\F\.julia_hid> Get-Content .\hidvid_044fpid_b10a6396faf92000004d1e55b2f16f11cf88cb001111000030.txt
[0, 0, 0, 63, 0, 32, 0, 32, 128, 129] - Raw data
1586283461.7795699 - Current time value

```


## Help wanted
It would be nice to have this working for other than Windows. Please help through submitting issues and pull requests!
