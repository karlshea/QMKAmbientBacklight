#include QMK_KEYBOARD_H

// Enable raw hid
#include "raw_hid.h"

// Needed for hid command structure
#include "via.h"

/**
 * Handle setting backlight over raw HID without VIA enabled.
 */

#ifndef VIA_ENABLE

#ifdef BACKLIGHT_ENABLE
#    if BACKLIGHT_LEVELS == 0
#        error BACKLIGHT_LEVELS == 0
#    endif

void via_qmk_backlight_set_value(uint8_t *data) {
    // data = [ value_id, value_data ]
    uint8_t *value_id   = &(data[0]);
    uint8_t *value_data = &(data[1]);
    switch (*value_id) {
        case id_qmk_backlight_brightness: {
            // level / 255 * BACKLIGHT_LEVELS
            backlight_level_noeeprom(((uint16_t)value_data[0]) * BACKLIGHT_LEVELS / UINT8_MAX);
            break;
        }
    }
}
#endif  // BACKLIGHT_ENABLE


void raw_hid_receive(uint8_t *data, uint8_t length) {
    uint8_t *command_id   = &(data[0]);
    uint8_t *command_data = &(data[1]);
    uint8_t *value_id_and_data = &(data[2]);

#if defined(BACKLIGHT_ENABLE)
    // data = [ command_id, channel_id, value_id, value_data ]

    if (*command_id == id_custom_set_value &&
        *command_data == id_qmk_backlight_channel) {
        via_qmk_backlight_set_value(value_id_and_data);
        return;
    }
#endif // BACKLIGHT_ENABLE

    *command_id = id_unhandled;
}

#endif // not VIA_ENABLE
