// Exercise ENet's actual ACK handler, including its RTT estimator and throttle.
// protocol.c is included so the test can call the otherwise private handler.
#include <stdio.h>
#include "protocol.c"

static int run_sequence(const char* name, unsigned low_samples, unsigned high_samples,
                        unsigned low_rtt, unsigned high_rtt, int expect_throttle)
{
  ENetAddress address = {0};
  if (enet_address_set_host_ip(&address, "127.0.0.1") != 0)
    return 1;
  ENetHost* host = enet_host_create(&address, 1, 3, 0, 0);
  if (!host)
  {
    fprintf(stderr, "%s: could not create local ENet host\n", name);
    return 1;
  }

  // enet_host_create initializes the real peer defaults and command queues.
  // No connection is attempted and no datagram is sent. Deliver synthetic ACK
  // timestamps directly to the real protocol handler in the connected state.
  ENetPeer* peer = host->peers;
  peer->state = ENET_PEER_STATE_CONNECTED;
  unsigned minimum_throttle = ENET_PEER_PACKET_THROTTLE_SCALE;
  int failed = 0;
  for (unsigned i = 0; i < low_samples + high_samples; ++i)
  {
    const unsigned rtt = i < low_samples ? low_rtt : high_rtt;
    host->serviceTime = 1000 + i * 500;
    ENetProtocol ack = {0};
    ack.header.channelID = 0xff;
    ack.acknowledge.receivedSentTime = ENET_HOST_TO_NET_16(host->serviceTime - rtt);
    ack.acknowledge.receivedReliableSequenceNumber = ENET_HOST_TO_NET_16(65535);
    if (enet_protocol_handle_acknowledge(host, NULL, peer, &ack) != 0)
    {
      fprintf(stderr, "%s: ACK handler failed at sample %u\n", name, i);
      failed = 1;
      break;
    }
    if (i >= low_samples && peer->packetThrottle < minimum_throttle)
      minimum_throttle = peer->packetThrottle;
    if (!expect_throttle && peer->packetThrottle != ENET_PEER_PACKET_THROTTLE_SCALE)
    {
      fprintf(stderr, "%s: prematurely throttled at sample %u (%u/%u)\n", name, i,
              peer->packetThrottle, ENET_PEER_PACKET_THROTTLE_SCALE);
      failed = 1;
      break;
    }
  }

  if (expect_throttle && minimum_throttle == ENET_PEER_PACKET_THROTTLE_SCALE)
  {
    fprintf(stderr, "%s: established-link congestion did not reduce throttle\n", name);
    failed = 1;
  }
  if (!failed)
    printf("PASS %s (minimum throttle %u/%u)\n", name, minimum_throttle,
           ENET_PEER_PACKET_THROTTLE_SCALE);

  peer->state = ENET_PEER_STATE_DISCONNECTED;
  enet_host_destroy(host);
  return failed;
}

int main(void)
{
  if (enet_initialize() != 0)
    return 1;
  int failed = 0;
  // A fast handshake followed by a slower path must retain Slippi's startup
  // smoothing; an unpatched ENet 1.3.18 drops to 30/32 on the second ACK.
  failed |= run_sequence("startup 27ms to 405ms", 1, 20, 27, 405, 0);
  failed |= run_sequence("stable 120ms", 1, 20, 120, 120, 0);
  // After 60 seconds of low RTT the estimator has converged. Real congestion
  // must still lower throttle, ruling out fixes that disable congestion control.
  failed |= run_sequence("converged 27ms to 405ms", 121, 20, 27, 405, 1);
  enet_deinitialize();
  return failed;
}
