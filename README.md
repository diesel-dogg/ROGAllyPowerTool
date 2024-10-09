# ABOUT THE PROJECT:
Simple win32 program to set TDP, CPU clock, GPU clock, FPS limit, maximum battery charge percentage etc. specifically made for the ROG Ally handhelds to customise power management on per-game basis. 


![Screenshot (26)](https://github.com/user-attachments/assets/1f963d62-b618-42f6-8310-0335242d4f8b)


# ROG Ally Power Tool:

PLEASE INSTALL THE LATEST RELEASE AND RUN WITH ADMINISTRATOR PRIVILEGES ON YOUR ALLY DEVICE

# INTENDED USE:
This tool is intended to allow users to conveniently set absolute TDP limits, CPU clock limits, FPS limit (via RTSS), and if absolutely necessary, also set a static clock for the GPU of their ROG Ally/AllyX device.
By limiting the CPU on per-game basis and assigning only a reasonable TDP limit for the game, it is often possible to divert additional power to the GPU while retaining a reasonable level of power consumption. 

# CAUTION AND DISCLAIMER:
- Due to the nature of the power profiles set up by Armoury Crate SE (ACSE), they will interfere with any attempts by the user to set a hard limit on the CPU clock. For this reason, this app will provide a way to override those profiles by setting up custom windows power profiles with the same names as the ACSE profiles but without the power slider. This will properly allow the user to set an AC and DC CPU clock limit.
- Each time the CPU clock is adjusted, the app will automatically set the windows power profile to Performance. This is only done as a convention and to ensure that users don’t have to constantly adjust brightness/power button settings etc for all kinds of different profiles. Note that the Performance, Silent, Turbo custom profiles all behave exactly the same.
- By accessing the ADVANCED menu of the app, these changes can be easily reversed and the ACSE power profiles can be restored. None of the changes made by this app are permanent. 
- It is not recommended to set a static GPU clock on these devices as the only reliable way to release the hard limit is to restart the device. The first release of the app did offer a way to reset the display driver with a button click but it does not achieve the desired effect on this GPU and the feature was later dropped. 
- Finally, I have extensively tested all features, including those that manipulate Windows registry, on my personal device and all changes that this app might make are reversible from within the app itself. That being said, it must be understood that the software herein is being made available on "As Is" basis with no warranties of any kind and no developer, contributor or facilitator associated with this project may be held responsible for any damage that might arise from its use.

# FEATURES:
- Ability to set CPU clock limit, TDP limit, FPS limit and static GPU clock.
- Checks are in place to prevent very high or low values from being set for any of the parameters. 
- Users can define any combination of the above as a profile with the click of a button. These profiles can be accessed and applied as needed from the PROFILES menu. This menu also includes 3 preset profiles. 
- The user-created profiles can be deleted or overwritten with ease. 
- The ADVANCED menu will allow the user to set the maximum battery charge percentage and configure the app to run on Windows startup through a scheduled task.
- The ADVANCED menu of the app further allows users to reinstall the custom power profiles that are required for correct operation of the CPU clock limit or restore the default ACSE power profiles. 
- A toggle is included in the ADVANCED menu to disable driver-level features from the registry, namely-- "EnableUlps" and "StutterMode". While disabling the Ultra Low Power State may not really have any effect on the Ally's GPU, I have observed a significant improvement in input latency and responsiveness by disabling AMD's counter-stutter feature. A good place to read on these features is the Guru3D forums. 
- App is programmed to use minimal CPU and GPU resources and rendering is paused when there is no activity. The app window is fully resizeable so that UI elements are not hidden on lower resolutions and users can adjust the size as needed. 
- UI is specifically designed to be conveniently navigated with touch input as well as mouse. 
- User created profiles are stored inside a subdirectory at the path C:/ROGAllyPowerTool. Presets are stored in a subdirectory at the /Resources path inside application directory. 

# LIMITATIONS:
- The CPU clock limits don’t seem to stick when the device is connected to AC power. I have done all the obvious steps and am applying limits for both AC and DC but I don’t currently have a fix for this. At any rate, limiting power use when on AC is not something that I imagine users need to care about. On battery, everything works. 
- Due to limitations of the LUA sandboxed environment in which the code is being executed, I am unable to use mappings for native Windows libraries and most operations are achieved through direct Windows commands which means that terminal windows will flash above the app's window-- albeit only momentarily and only when an in-app setting is adjusted.

# ACKNOWLEDGEMENTS:
- RyzenAdj, RTSSCLI are the command line tools used for TDP control and RTSS interface. 
- App is built on a custom fork of Solar2D
- Custom windows power plans and bat scripts to install/uninstall these plans provided by Ciphray from the GPD Discord server

# BUILDING
I will be uploading prebuilt non-debug releases for windows but if you'd like to build, you will need to setup the full solar2d environment on an x86 windows machine. See their website for guidance.
A custom LUA library is being used from v1.2.0 onwards to enable some system calls which are otherwise blocked in Solar2D. If anyone should like to build the app, they can contact me for the modified DLLs.


![Screenshot (25)](https://github.com/user-attachments/assets/3a94d585-c5d7-45b5-a157-9cb9461b1e0a)

![Screenshot (34)](https://github.com/user-attachments/assets/04eea871-d50a-4bfd-a343-6c00041496b4)

![Screenshot (28)](https://github.com/user-attachments/assets/2a797c8e-5e93-4945-b3b5-5981566cca60)

