#include <enet/enet.h>
#include <stdio.h>
#include <unistd.h>
static const ENetPeer *expected;
static unsigned observed, sent_packets, discarded_packets;
static void packet_freed(ENetPacket *p) {
    if (p->flags & ENET_PACKET_FLAG_SENT) ++sent_packets;
    else ++discarded_packets;
}
static int send_packet(ENetPeer *peer) {
    ENetPacket *p=enet_packet_create("test",4,ENET_PACKET_FLAG_UNSEQUENCED);
    if (!p) return 1;
    p->freeCallback=packet_freed;
    if (enet_peer_send(peer,1,p)) { enet_packet_destroy(p); return 1; }
    return 0;
}
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
    cp->packetThrottle=32;
    for (int i=0;i<32;++i) { if(send_packet(cp)) return 6; enet_host_flush(c); }
    if(sent_packets!=32 || discarded_packets) return 7;
    sent_packets=discarded_packets=0; cp->packetThrottle=0;
    for (int i=0;i<32;++i) { if(send_packet(cp)) return 8; enet_host_flush(c); }
    if(sent_packets!=1 || discarded_packets!=31) return 9;
    sent_packets=discarded_packets=0;
    if(send_packet(cp)) return 10;
    enet_peer_reset(cp);
    if(sent_packets || discarded_packets!=1) return 11;
    enet_host_destroy(c); enet_host_destroy(s); enet_deinitialize();
    puts("PASS: actual ENet distinguishes sent, throttle-discarded and cleanup-discarded unsequenced packets");
    return 0;
}
