# QMK Ambient Backlight

Automatically set your keyboard's backlight based on your Mac's ambient light sensor.

## Compatibility

**macOS Big Sur or later and a Mac with a built-in ambient light sensor.**

Your keyboard must be running the [QMK](https://qmk.fm/) firmware, with the following additional requirements:

### Either

 * VIA enabled (`VIA_ENABLE = yes` in your `rules.mk`)

### Or

 * `RAW_ENABLE = yes` in your `rules.mk`
 * The contents of [example-keymap.c](./example-keymap.c) included in your `keymap.c`
 * A decent number of levels set for `BACKLIGHT_LEVELS` in your `config.h` (e.g. 10 or more)

## Acknowledgements

This is my first macOS/SwiftUI project. Most of the project structure was inspired by and the entirety of the code for the ambient light sensor was taken from [DarkModeBuddy](https://github.com/insidegui/DarkModeBuddy) by Guilherme Rambo.