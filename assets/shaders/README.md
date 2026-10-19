# Bundled video shaders

These GLSL shaders are applied to libmpv with the `glsl-shaders` property.

- Anime4K (https://github.com/bloc97/Anime4K), MIT License.
  - `Anime4K_Clamp_Highlights.glsl`
  - `Anime4K_Restore_CNN_M.glsl`
  - `Anime4K_Upscale_CNN_x2_M.glsl`
- Copyright (c) 2019-2021 bloc97. See `ANIME4K_LICENSE.txt`.

The shaders are bundled unmodified. They are experimental under media_kit's
ANGLE/OpenGL video output; if libmpv rejects a shader the app falls back to
normal playback instead of failing.
