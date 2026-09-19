/* Verify classification at ENet's real pre-reset decision points. */
#include <stdio.h>
#define MELEEPAD_ENET_EXTERNAL_DIAGNOSTICS 1
#include "protocol.c"

static unsigned observed, observed_rtt, observed_ack_age;
void meleepad_enet_disconnect_observed(const ENetPeer *peer, unsigned cause, unsigned now)
{
    observed = cause;
    observed_rtt = peer->roundTripTime;
    observed_ack_age = now - peer->lastReceiveTime;
}

int main(void)
{
    if (enet_initialize()) return 1;
    ENetHost *host = enet_host_create(NULL, 1, 3, 0, 0);
    if (!host) return 2;
    ENetPeer *peer = host->peers;
    peer->state = ENET_PEER_STATE_CONNECTED;
    peer->roundTripTime = 27;
    peer->lastReceiveTime = 1990;
    host->serviceTime = 2000;
    ENetProtocol command = {0};
    command.header.command = ENET_PROTOCOL_COMMAND_DISCONNECT | ENET_PROTOCOL_COMMAND_FLAG_ACKNOWLEDGE;
    /* An explicit remote disconnect may legitimately carry reason zero. */
    if (enet_protocol_handle_disconnect(host, peer, &command) || observed != 1 ||
        observed_rtt != 27 || observed_ack_age != 10 || peer->eventData != 0)
        return 3;
    enet_peer_reset(peer);
    observed = 0;
    if (enet_protocol_handle_disconnect(host, peer, &command) || observed) return 4;

    peer->state = ENET_PEER_STATE_CONNECTED;
    peer->roundTripTime = 800;
    peer->lastReceiveTime = 1000;
    peer->timeoutMaximum = 100;
    ENetOutgoingCommand *pending = enet_malloc(sizeof(*pending));
    if (!pending) return 5;
    memset(pending, 0, sizeof(*pending));
    pending->sentTime = 1000;
    pending->roundTripTimeout = 1;
    pending->sendAttempts = 1;
    enet_list_insert(enet_list_end(&peer->sentReliableCommands), pending);
    ENetEvent event = {0};
    if (!enet_protocol_check_timeouts(host, peer, &event) || observed != 2 ||
        observed_rtt != 800 || observed_ack_age != 1000 ||
        event.type != ENET_EVENT_TYPE_DISCONNECT || event.data != 0)
        return 6;
    enet_host_destroy(host);
    enet_deinitialize();
    puts("PASS: remote reason-zero disconnect and local reliable timeout distinguished before reset");
    return 0;
}
