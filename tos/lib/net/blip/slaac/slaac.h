#ifndef __SLAAC_H__
#define __SLAAC_H__

#define SLAACADDR_ALLROUTER "ff02::2"

enum {
  SLAAC_SOURCE_LINK_LAYER_ADDR = 1,
  SLAAC_TARGET_LINK_LAYER_ADDR = 2,
  SLAAC_PREFIX_INFORMATION = 3,
  SLAAC_REDIRECTED_HEADER = 4,
  SLAAC_MTU = 5,
};

struct slaac_rtr_sol_t {
  struct icmpv6_header_t icmpv6;
  nx_uint32_t reserved;
};

struct slaac_rtr_adv_t {
  struct icmpv6_header_t icmpv6;
  uint8_t hop_limit;
  uint8_t m_bit    : 1;
  uint8_t o_bit    : 1;
  uint8_t reserved : 6;
  nx_uint16_t router_lifetime;
  nx_uint32_t reachable_time;
  nx_uint32_t retrans_time;
} __attribute__((packed));

struct slaac_opt_prefix_t {
  uint8_t type;
  uint8_t length;
  uint8_t prefix_length;
  uint8_t l_bit     : 1;
  uint8_t a_bit     : 1;
  uint8_t reserved1 : 6;
  nx_uint32_t valid_lifetime;
  nx_uint32_t preferred_lifetime;
  nx_uint32_t reserved2;
  struct in6_addr prefix;
} __attribute__((packed));

struct rtr_adv_full_t {
  struct slaac_rt_adv_t adv_hdr;
  struct slaac_opt_prefix_t prefix_opt;
};

#endif
