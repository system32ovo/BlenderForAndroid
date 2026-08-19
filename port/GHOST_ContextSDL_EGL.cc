/* SPDX-FileCopyrightText: 2025 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup GHOST
 */

#include "GHOST_ContextSDL_EGL.hh"

#include <cstdio>

GHOST_ContextSDL_EGL::GHOST_ContextSDL_EGL(
    const GHOST_System *const system,
    const GHOST_ContextParams &context_params,
    SDL_Window *sdl_window,
    int contextMajorVersion,
    int contextMinorVersion,
    int contextFlags,
    int contextResetNotificationStrategy)
    : GHOST_ContextEGL(
          system,
          context_params,
          /* nativeWindow: Get ANativeWindow from SDL. When nullptr (offscreen) a
           * 1x1 PBuffer surface is used instead. */
          sdl_window ?
              (EGLNativeWindowType)SDL_GetPointerProperty(
                  SDL_GetWindowProperties(sdl_window),
                  SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER,
                  nullptr) :
              0,
          /* nativeDisplay: EGL_DEFAULT_DISPLAY on Android. */
          EGL_DEFAULT_DISPLAY,
          /* contextProfileMask: Not used for GLES, must be 0. */
          0,
          contextMajorVersion,
          contextMinorVersion,
          contextFlags,
          contextResetNotificationStrategy,
          /* api: OpenGL ES on Android, no desktop GL. */
          EGL_OPENGL_ES_API)
{
}