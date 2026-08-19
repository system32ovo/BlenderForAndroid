/* SPDX-FileCopyrightText: 2025 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup GHOST
 *
 * EGL context backed by SDL3 window on Android.
 * Extracts the native ANativeWindow from SDL and uses EGL_DEFAULT_DISPLAY.
 */

#pragma once

#include "GHOST_ContextEGL.hh"

#include <SDL3/SDL.h>

class GHOST_ContextSDL_EGL : public GHOST_ContextEGL {
 public:
  GHOST_ContextSDL_EGL(const GHOST_System *const system,
                       const GHOST_ContextParams &context_params,
                       SDL_Window *sdl_window,
                       int contextMajorVersion,
                       int contextMinorVersion,
                       int contextFlags,
                       int contextResetNotificationStrategy);

  ~GHOST_ContextSDL_EGL() override = default;
};