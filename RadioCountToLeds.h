#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct radio_count_msg {
  nx_uint16_t counter;
  nx_uint16_t src;
  nx_uint16_t hour;
  nx_uint16_t min;
  nx_uint16_t sec;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif