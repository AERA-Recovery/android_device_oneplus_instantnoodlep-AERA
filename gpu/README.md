# OnePlus 8 Pro Recovery Graphics

The ARM64 graphics libraries in `recovery/root/vendor` come from the owner's
extracted OnePlus 8 Pro OxygenOS full OTA. They match the existing stock kernel,
DTB and Adreno 650 firmware. No kernel or touchscreen driver is replaced.

The bundled stack contains Adreno EGL/GLES2, its shader compiler, the Android
EGL subdriver, Kona gralloc/mapper and their required library dependencies.
The matching stock `libnativewindow`, `libui` and graphics interface libraries
provide Android native buffers to AERA's existing zero-copy DRM renderer.

`aera-gralloc.rc` starts the stock graphics allocator HAL. Its VINTF declarations
and the passthrough mapper declarations are bundled as well. The allocator can
start before data decryption and does not require files from the installed ROM.
SurfaceFlinger, Vulkan, OpenCL and the stock display composer are not included.

Live validation on the device confirmed Qualcomm Adreno 650 EGL 1.5, correct
pbuffer pixels, successful native-buffer allocation and EGLImage rendering,
and AERA's `zero-copy Adreno/LVGL` rendering with double DRM scanout buffers.
If initialization fails, AERA retains its existing software rendering fallback.
