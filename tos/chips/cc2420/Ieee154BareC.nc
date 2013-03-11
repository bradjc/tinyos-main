
/* Provides an abstraction layer for complete access to an 802.15.4 packet
 * buffer. Packets provided to this module will be interpreted as 802.15.4
 * frames and will have the sequence number set. All other fields must be set
 * by upper layers.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration Ieee154BareC {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;
  }
}

implementation {
  components CC2420RadioC;

  SplitControl = CC2420RadioC.SplitControl;

  BarePacket = CC2420RadioC.BarePacket;
  BareSend = CC2420RadioC.BareSend;
  BareReceive = CC2420RadioC.BareReceive;
}
