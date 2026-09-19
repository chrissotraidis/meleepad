// Private ModernGekko diagnostic mod. It observes the native Slippi item
// loop after itemData is loaded and leaves CPUState untouched; it is not a
// gameplay mod.
#include "moderngekko/mod_abi.h"

#include <stdio.h>
#include <stdlib.h>

static unsigned calls;
static unsigned spawn_calls;
static FILE* output;
static FILE* spawn_output;

static void CaptureItemProcedure(CPUState* state)
{
    if (!state || calls >= 64u)
        return;
    if (!output) {
        const char* path = getenv("SLIPPI_PROBE_HOOK_LOG");
        output = path && path[0] ? fopen(path, "a") : stderr;
    }
    if (!output)
        return;
    const uint32_t item = state->gpr[28];
    const uint32_t id = (uint32_t)moderngekko_mod_read(state, item + 0x10u, 4u);
    const uint32_t item_state = (uint32_t)moderngekko_mod_read(state, item + 0x24u, 4u);
    const uint32_t direction = (uint32_t)moderngekko_mod_read(state, item + 0x2Cu, 4u);
    const uint32_t x_velocity = (uint32_t)moderngekko_mod_read(state, item + 0x40u, 4u);
    const uint32_t y_velocity = (uint32_t)moderngekko_mod_read(state, item + 0x44u, 4u);
    const uint32_t x_position = (uint32_t)moderngekko_mod_read(state, item + 0x4Cu, 4u);
    const uint32_t y_position = (uint32_t)moderngekko_mod_read(state, item + 0x50u, 4u);
    const uint32_t damage = (uint32_t)moderngekko_mod_read(state, item + 0xC9Cu, 2u);
    const uint32_t expiry = (uint32_t)moderngekko_mod_read(state, item + 0xD44u, 4u);
    const uint32_t spawn = (uint32_t)moderngekko_mod_read(state, item + 0x1Cu, 4u);
    const uint32_t metadata_1 = (uint32_t)moderngekko_mod_read(state, item + 0xDD7u, 1u);
    const uint32_t metadata_2 = (uint32_t)moderngekko_mod_read(state, item + 0xDDBu, 1u);
    const uint32_t metadata_3 = (uint32_t)moderngekko_mod_read(state, item + 0xDEBu, 1u);
    const uint32_t metadata_4 = (uint32_t)moderngekko_mod_read(state, item + 0xDEFu, 1u);
    const uint32_t instance = (uint32_t)moderngekko_mod_read(state, item + 0xDA8u, 2u);
    fprintf(output,
            "send_item_hook,%u,pc=%08x,item=%08x,gobj=%08x,buffer=%08x,offset=%08x,count=%08x,id=%08x,state=%08x,direction=%08x,xvel=%08x,yvel=%08x,xpos=%08x,ypos=%08x,damage=%08x,expiry=%08x,spawn=%08x,meta=%02x%02x%02x%02x,instance=%04x\n",
            calls, state->pc, item, state->gpr[29], state->gpr[31], state->gpr[30], state->gpr[27],
            id, item_state, direction, x_velocity, y_velocity, x_position, y_position, damage, expiry,
            spawn, metadata_1, metadata_2, metadata_3, metadata_4, instance);
    fflush(output);
    ++calls;
}

static void CaptureSpawnProcedure(CPUState* state)
{
    if (!state || spawn_calls >= 64u)
        return;
    if (!spawn_output) {
        const char* path = getenv("SLIPPI_PROBE_SPAWN_HOOK_LOG");
        spawn_output = path && path[0] ? fopen(path, "w") : stderr;
    }
    if (!spawn_output)
        return;
    const uint32_t spawn = state->gpr[3];
    const uint32_t parent = (uint32_t)moderngekko_mod_read(state, spawn + 0x00u, 4u);
    const uint32_t parent2 = (uint32_t)moderngekko_mod_read(state, spawn + 0x04u, 4u);
    const uint32_t kind = (uint32_t)moderngekko_mod_read(state, spawn + 0x08u, 4u);
    const uint32_t hold = (uint32_t)moderngekko_mod_read(state, spawn + 0x0Cu, 4u);
    const uint32_t x10 = (uint32_t)moderngekko_mod_read(state, spawn + 0x10u, 4u);
    const uint32_t xpos = (uint32_t)moderngekko_mod_read(state, spawn + 0x14u, 4u);
    const uint32_t ypos = (uint32_t)moderngekko_mod_read(state, spawn + 0x18u, 4u);
    const uint32_t zpos = (uint32_t)moderngekko_mod_read(state, spawn + 0x1Cu, 4u);
    const uint32_t prevx = (uint32_t)moderngekko_mod_read(state, spawn + 0x20u, 4u);
    const uint32_t prevy = (uint32_t)moderngekko_mod_read(state, spawn + 0x24u, 4u);
    const uint32_t prevz = (uint32_t)moderngekko_mod_read(state, spawn + 0x28u, 4u);
    const uint32_t velx = (uint32_t)moderngekko_mod_read(state, spawn + 0x2Cu, 4u);
    const uint32_t vely = (uint32_t)moderngekko_mod_read(state, spawn + 0x30u, 4u);
    const uint32_t velz = (uint32_t)moderngekko_mod_read(state, spawn + 0x34u, 4u);
    const uint32_t facing = (uint32_t)moderngekko_mod_read(state, spawn + 0x38u, 4u);
    const uint32_t damage = (uint32_t)moderngekko_mod_read(state, spawn + 0x3Cu, 2u);
    const uint32_t x40 = (uint32_t)moderngekko_mod_read(state, spawn + 0x40u, 4u);
    const uint32_t flags = (uint32_t)moderngekko_mod_read(state, spawn + 0x44u, 4u);
    const uint32_t ground = (uint32_t)moderngekko_mod_read(state, spawn + 0x48u, 4u);
    fprintf(spawn_output,
            "spawn_hook,%u,pc=%08x,spawn=%08x,parent=%08x,parent2=%08x,kind=%08x,hold=%08x,x10=%08x,xpos=%08x,ypos=%08x,zpos=%08x,prevx=%08x,prevy=%08x,prevz=%08x,velx=%08x,vely=%08x,velz=%08x,facing=%08x,damage=%04x,x40=%08x,flags=%08x,ground=%08x\n",
            spawn_calls, state->pc, spawn, parent, parent2, kind, hold, x10,
            xpos, ypos, zpos, prevx, prevy, prevz, velx, vely, velz, facing,
            damage, x40, flags, ground);
    fflush(spawn_output);
    ++spawn_calls;
}

static const ModernGekkoModHook hooks[] = {
    RECOMP_HOOK(0x8065EBD0u, CaptureItemProcedure),
    RECOMP_HOOK(0x8026862Cu, CaptureSpawnProcedure),
};

static const ModernGekkoModDesc descriptor = {
    MODERNGEKKO_MOD_ABI_VERSION,
    MODERNGEKKO_CPU_ABI_VERSION,
    sizeof(CPUState),
    "GALE01",
    "slippi-send-item-hook",
    "0.1.0",
    "Slippi SendItemInfo hook diagnostic",
    0,
    0u,
    0,
    0u,
    hooks,
    2u,
    0,
    0u,
    0,
    0u,
    0,
    0u,
    0,
    0u,
    0,
    0,
};

MODERNGEKKO_MOD_EXPORT const ModernGekkoModDesc* moderngekko_get_mod(void)
{
    return &descriptor;
}
