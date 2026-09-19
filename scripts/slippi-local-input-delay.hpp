#pragma once
// Isolated PAD delivery delay. Queue stays on the existing network thread;
// handshake, receive, ACK and disconnect handling are not put to sleep.
#include <atomic>
#include <deque>
#include <functional>
#include <cstring>
#include "Core/Slippi/SlippiWire.h"
namespace SlippiLocalInputDelay {
inline std::atomic<unsigned long long> enqueued{0}, released{0}, overflow{0}, max_hold_us{0};
struct Queue {
  struct Entry { u64 queued, due; sf::Packet packet; };
  std::deque<Entry> entries;
  unsigned milliseconds;
  explicit Queue(unsigned ms) : milliseconds(ms) {}
  template<typename Send> void Submit(sf::Packet& packet, u64 now, Send send) {
    const auto* bytes = static_cast<const u8*>(packet.getData());
    if (milliseconds && packet.getDataSize() >= 5 && bytes[0] == static_cast<u8>(SlippiWire::MessageID::SLIPPI_PAD)) {
      const s32 frame = static_cast<s32>((u32(bytes[1])<<24)|(u32(bytes[2])<<16)|(u32(bytes[3])<<8)|bytes[4]);
      if (frame >= 120) {
        if (entries.size() >= 1024) { ++overflow; return; }
        entries.push_back({now, now + u64(milliseconds)*1000, packet}); ++enqueued; return;
      }
    }
    send(packet);
  }
  template<typename Send> void Flush(u64 now, Send send) {
    while (!entries.empty() && entries.front().due <= now) {
      auto& e=entries.front(); send(e.packet); ++released;
      const auto hold=now-e.queued;
      if (hold > max_hold_us.load()) max_hold_us=hold;
      entries.pop_front();
    }
  }
  unsigned PollTimeout(u64 now) const {
    if (entries.empty()) return 250;
    if (entries.front().due <= now) return 0;
    return static_cast<unsigned>(std::min<u64>(250,(entries.front().due-now+999)/1000));
  }
};
}
