#pragma once

#include "image.h"

#ifdef HAS_ENCODER
bool image_load_rggb(const char *filename, Image& image);
#endif
bool image_save_rggb(const char *filename, const Image& image);
