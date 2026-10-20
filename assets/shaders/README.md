# Bundled video shaders

These GLSL shaders are applied to libmpv with the `glsl-shaders` property.

- Anime4K (https://github.com/bloc97/Anime4K), MIT License.
  - `Anime4K_Clamp_Highlights.glsl`
  - `Anime4K_Restore_CNN_M.glsl` — standard restore
  - `Anime4K_Restore_CNN_L.glsl` — stronger restore
  - `Anime4K_Upscale_CNN_x2_M.glsl` — 2x upscale
  - `Anime4K_Upscale_CNN_x2_M_2.glsl` — identical second pass for 4x
- Copyright (c) 2019-2021 bloc97. See `ANIME4K_LICENSE.txt`.

Profiles:

- **Fast 2x**: Clamp + M upscale.
- **Balanced 2x**: Clamp + M restore + M upscale.
- **Strong 2x**: Clamp + L restore + M upscale.
- **4x**: Clamp + M restore + M upscale + M upscale (two identical 2x passes).

The shaders are bundled unmodified. They are experimental under media_kit's
ANGLE/OpenGL video output; if libmpv rejects a shader the app falls back to
normal playback instead of failing.
