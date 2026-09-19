/* Exercise actual UDP delivery while ENet has incoming events queued. */
#include <enet/enet.h>
#include <stdio.h>
#include <unistd.h>

static void discard(ENetEvent *event)
{
  if (event->type == ENET_EVENT_TYPE_RECEIVE)
    enet_packet_destroy(event->packet);
}

static int check(int flush_now)
{
  int result = 0, found = 0;
  ENetAddress address = {0};
  enet_address_set_host_ip(&address, "127.0.0.1");
  ENetHost *server = enet_host_create(&address, 1, 3, 0, 0);
  ENetHost *client = enet_host_create(&address, 1, 3, 0, 0);
#define REQUIRE(condition, code) do { if (!(condition)) { result = code; goto cleanup; } } while (0)
  REQUIRE(server && client, 1);
  ENetPeer *remote = NULL;
  ENetPeer *peer = enet_host_connect(client, &server->address, 3, 0);
  ENetEvent event;
  REQUIRE(peer, 2);
  for (int i = 0; i < 1000 && (!remote || peer->state != ENET_PEER_STATE_CONNECTED); ++i)
  {
    if (enet_host_service(client, &event, 0) > 0)
      discard(&event);
    if (enet_host_service(server, &event, 0) > 0)
    {
      if (event.type == ENET_EVENT_TYPE_CONNECT)
        remote = event.peer;
      discard(&event);
    }
    usleep(1000);
  }
  REQUIRE(remote && peer->state == ENET_PEER_STATE_CONNECTED, 3);
  for (int i = 0; i < 8; ++i)
  {
    unsigned char payload = (unsigned char)i;
    REQUIRE(enet_peer_send(remote, 1,
        enet_packet_create(&payload, 1, ENET_PACKET_FLAG_UNSEQUENCED)) == 0, 4);
  }
  enet_host_flush(server);
  for (int i = 0; i < 100; ++i)
  {
    if (enet_host_service(client, &event, 1) > 0)
    {
      int received = event.type == ENET_EVENT_TYPE_RECEIVE;
      discard(&event);
      if (received)
        break;
    }
  }
  REQUIRE(!enet_list_empty(&client->dispatchQueue), 5);
  unsigned before = client->totalSentPackets;
  /* Match Slippi's input and acknowledgement channels and packet flags. */
  for (unsigned char channel = 1; channel <= 2; ++channel)
    REQUIRE(enet_peer_send(peer, channel,
        enet_packet_create(&channel, 1, ENET_PACKET_FLAG_UNSEQUENCED)) == 0, 6);
  if (flush_now)
    enet_host_flush(client);
  REQUIRE(enet_host_service(client, &event, 0) > 0, 7);
  int received = event.type == ENET_EVENT_TYPE_RECEIVE;
  discard(&event);
  REQUIRE(received, 8);
  unsigned sent = client->totalSentPackets - before;
  REQUIRE(flush_now ? sent > 0 : sent == 0, 9);
  for (int i = 0; i < 20; ++i)
  {
    if (enet_host_service(server, &event, 1) > 0)
    {
      if (event.type == ENET_EVENT_TYPE_RECEIVE && event.packet->dataLength == 1 &&
          event.packet->data[0] == event.channelID &&
          (event.channelID == 1 || event.channelID == 2))
        found |= 1 << event.channelID;
      discard(&event);
    }
  }
  REQUIRE(found == (flush_now ? 6 : 0), 10);
  printf("%s: sent=%u input=%d ack=%d while incoming dispatch remains queued\n",
         flush_now ? "explicit flush" : "baseline", sent, !!(found & 2), !!(found & 4));
cleanup:
  if (client) enet_host_destroy(client);
  if (server) enet_host_destroy(server);
  if (result) fprintf(stderr, "flush=%d failed check %d\n", flush_now, result);
  return result;
#undef REQUIRE
}

int main(void)
{
  if (enet_initialize()) return 1;
  int baseline = check(0), candidate = check(1);
  enet_deinitialize();
  return baseline || candidate;
}
