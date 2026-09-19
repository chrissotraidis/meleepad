#include <enet/enet.h>
#include <stdio.h>
#include <unistd.h>
static const ENetPeer *expected;
static unsigned observed;
void meleepad_enet_disconnect_observed(const ENetPeer *peer, unsigned cause, unsigned now)
{
    (void)now;
    if (peer == expected) observed = cause;
}
static void discard(ENetEvent *e) {
    if (e->type == ENET_EVENT_TYPE_RECEIVE) enet_packet_destroy(e->packet);
}
int main(void) {
    if (enet_initialize()) return 1;
    ENetAddress a = {0}; enet_address_set_host_ip(&a, "127.0.0.1");
    ENetHost *s = enet_host_create(&a, 1, 3, 0, 0), *c = enet_host_create(&a, 1, 3, 0, 0);
    if (!s || !c) return 2;
    ENetPeer *cp = enet_host_connect(c, &s->address, 3, 0), *sp = NULL;
    if (!cp) return 3;
    expected = cp;
    ENetEvent e;
    for (int i=0; i<1000 && (!sp || cp->state != ENET_PEER_STATE_CONNECTED); ++i) {
        if (enet_host_service(c, &e, 0)>0) discard(&e);
        if (enet_host_service(s, &e, 0)>0) {
            if (e.type == ENET_EVENT_TYPE_CONNECT) sp=e.peer;
            discard(&e);
        }
        usleep(1000);
    }
    if (!sp || cp->state != ENET_PEER_STATE_CONNECTED) return 4;
    enet_peer_disconnect_now(sp, 0);
    int disconnected = 0;
    for (int i=0; i<100 && !disconnected; ++i) {
        if (enet_host_service(c, &e, 10)>0) {
            disconnected = e.type == ENET_EVENT_TYPE_DISCONNECT && e.data == 0;
            discard(&e);
        }
    }
    enet_host_destroy(c); enet_host_destroy(s); enet_deinitialize();
    if (!disconnected || observed != 1) return 5;
    puts("PASS: separately linked observer overrides weak default and classifies real UDP disconnect");
    return 0;
}
