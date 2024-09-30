# ABOUT THE PROJECT:
Simple win32 program to set TDP, CPU clock, GPU clock, FPS limit (and probably more features in the future) specifically made for the ROG Ally handhelds to customise power management on per-game basis. 

# ROG Ally Power Tool:

PLEASE INSTALL THE LATEST RELEASE AND RUN WITH ADMINISTRATOR PRIVILEGES ON YOUR ALLY DEVICE

# INTENDED USE:
This tool is intended to allow users to conveniently set absolute TDP limits, CPU clock limits, FPS limit (via RTSS), and if absolutely necessary, also set a static clock for the GPU of their ROG Ally/AllyX device.
By limiting the CPU on per-game basis and assigning only a reasonable TDP limit for the game, it is often possible to divert additional power to the GPU while retaining a reasonable level of power consumption. 

# CAUTION:
- Due to the nature of the power profiles set up by Armoury Crate SE (ACSE), they will interfere with any attempts by the user to set a hard limit on the CPU clock. For this reason, this app will provide a way to override those profiles by setting up custom windows power profiles with the same names as the ACSE profiles but without the power slider. This will properly allow the user to set an AC and DC CPU clock limit.
- Each time the CPU clock is adjusted, the app will automatically set the windows power profile to Performance. This is only done as a convention and to ensure that users don’t have to constantly adjust brightness/power button settings etc for all kinds of different profiles. Note that the Performance, Silent, Turbo custom profiles all behave exactly the same.
- By accessing the ADVANCED menu of the app, these changes can be easily reversed and the ACSE power profiles can be restored. None of the changes made by this app are permanent. 
- It is not recommended to set a static GPU clock on these devices as the only reliable way to release the hard limit is to restart the device. The app does offer a way to restart the display driver which might work for other AMD chips but it is not expected to have any particular benefit for the Ally/AllyX devices’ APU.

# FEATURES:
- Ability to set CPU clock limit, TDP limit, FPS limit and static GPU clock.
- Checks are in place to prevent very high or low values from being set for any of the parameters. 
- Users can define any combination of the above as a profile with the click of a button. These profiles can be accessed and applied as needed from the PROFILES menu. This menu also includes 3 preset profiles. 
- The user-created profiles can be deleted or overwritten with ease. 
- The ADVANCED menu of the app allows users to reinstall the custom power profiles that are required for correct operation of the CPU clock limit or restore the default ACSE power profiles. 
- App is programmed to use minimal CPU and GPU resources and rendering is paused when there is no activity. The app window is fully resizeable so that UI elements are not hidden on lower resolutions and users can adjust the size as needed. 
- UI is specifically designed to be conveniently navigated with touch input as well as mouse. 

# LIMITATIONS:
- The CPU clock limits don’t seem to stick when the device is connected to AC power. I have done all the obvious steps and am applying limits for both AC and DC but I don’t currently have a fix for this. At any rate, limiting power use when on AC is not something that I imagine users need to care about. On battery, everything works. 
- All OS level commands that are executed will cause a terminal window to flash momentarily which can be a little annoying at first. This is due to the security restrictions of the sandboxed Lua environment in which the app is running. I am looking to work around this problem for a future release. 

# ACKNOWLEDGEMENTS:
- RyzenAdj, RTSSCLI are the command line tools used for TDP control and RTSS interface. 
- App is built on a custom fork of Solar2D
- Custom windows power plans and bat scripts to install/uninstall these plans provided by Ciphray from the GPD Discord server

# BUILDING
I will be uploading prebuilt non-debug releases for windows but if you'd like to build, you will need to setup the full solar2d environment on an x86 windows machine. See their website for guidance.
