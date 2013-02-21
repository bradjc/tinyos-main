#include "slaac.h"
#include "ip.h"

module SlaacClientP {
  provides {
    interface StdControl;
  }
  uses {
    interface IP as IP_RS;
    interface IP as IP_RA;
    interface IPAddress;
    interface Timer<TMilli>;
    interface Random;
  }
}

implementation {

  #define TIMER_PERIOD 15

  struct rtr_adv_full_t adv_full;
  bool adv_full_valid = FALSE;

  command error_t StdControl.start() {
    call Timer.startOneShot((1024L * TIMER_PERIOD) % (call Random.rand16()));
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call Timer.stop();
    call IPAddress.removeAddress();
    return SUCCESS;
  }

  void send_solicit () {
    struct ip6_packet pkt;
    struct ip_iovec v[1];
    struct slaac_rtr_sol_t msg;
    uint16_t length;

    length = sizeof(struct slaac_rtr_sol_t);

    msg.icmpv6.type = ICMP_TYPE_ROUTER_SOL;
    msg.icmpv6.code = 0;
    msg.icmpv6.checksum = 0;

    pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    pkt.ip6_hdr.ip6_plen = htons(length);

    v[0].iov_base = (uint8_t*) &msg;
    v[0].iov_len  = length;
    v[0].iov_next = NULL;
    pkt.ip6_data = &v[0];

    inet_pton6(SLAACADDR_ALLROUTER, &pkt.ip6_hdr.ip6_dst.sin6_addr);
    call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);

    call IP_RS.send(&pkt);

  }

  event void Timer.fired() {
    // state machine transition timeouts
    if (!call Timer.isRunning()) {
      call Timer.startPeriodic(1024L * TIMER_PERIOD);
    }

    send_solicit();
  }

  // Receiving a Router Advertisement.
  // This will contain the prefix we should use.
  event void IP_RA.recv(struct ip6_hdr *iph,
                        void *payload,
                        size_t len,
                        struct ip6_metadata *meta) {

    struct slaac_rtr_adv_t* adv = (struct slaac_rtr_adv_t*) payload;
    struct slaac_opt_prefix_t* opt_prefix;
    uint8_t* buf = (uint8_t*) payload;
    struct in6_addr addr;
    uint8_t* adv_full_buf = (uint8_t*) adv_full;

    // save the adv message
    memcpy(adv_full_buf, adv, sizeof(struct slaac_rtr_adv_t));
    adv_full_buf += sizeof(struct slaac_rtr_adv_t);

    buf += sizeof(struct slaac_rtr_adv_t);
    len -= sizeof(struct slaac_rtr_adv_t);

    while (len > 0) {
      if (buf[0] == SLAAC_PREFIX_INFORMATION) {
        break;
      }
      // Didn't find the prefix header we were looking for, so skip this
      // option and keep searching.
      // Multiply by 8 because the length field is in units of 8 octets.
      buf += buf[1] * 8;
      len -= buf[1] * 8;
    }

    if (len == 0) {
      return;
    }

    // Found the prefix header
    opt_prefix = (struct slaac_opt_prefix_t*) buf;
    if (opt_prefix->prefix_length > 64) {
      // This prefix is too long and is useless to us.
      printf("SLAAC: Prefix too long: %i\n", opt_prefix->prefix_length);
      return;
    }

    // Copy in the interface identifier from the link local address.
    // Not quite ignoring the bits not in the prefix, but they are 0 and it
    // is easier to do it this way.
    call IPAddress.getLLAddr(addr);
    memcpy(addr, opt_prefix->prefix, 64);

    call IPAddress.setAddress(addr);

    call Timer.stop();

    // save the prefix
    memcpy(adv_full_buf, opt_prefix, sizeof(struct slaac_opt_prefix_t));

    // TODO: handle the valid lifetime

  }

  event void IP_RS.recv(struct ip6_hdr *iph,
                        void *payload,
                        size_t len,
                        struct ip6_metadata *meta) {

    if (adv_full_valid == FALSE) {
      // Haven't yet seen a router advertisement, can't reply
      return;
    }

    // Send the router adv we got

  }

  event void IPAddress.changed(bool global_valid) {}

}
