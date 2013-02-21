
configuration SlaacClientC {
}
implementation {
  components SlaacClientP;
  components IPStackControlP;
  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_SOL) as ICMP_RS;
  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_ADV) as ICMP_RA;
  components IPAddressC;
  components new TimerMilliC();
  components RandomC;

  IPStackControlP.StdControl -> SlaacClientP;

  SlaacClientP.IP_RS -> ICMP_RS.IP[0];
  SlaacClientP.IP_RA -> ICMP_RA.IP[0];
  SlaacClientP.IPAddress -> IPAddressC;
  SlaacClientP.Timer -> TimerMilliC;
  SlaacClientP.Random -> RandomC;
}
