// Loopback-only, two-fixture matchmaking server. Never a production service.
// Accepts only the synthetic identities created by probe-slippi-local-game.py.
#include <enet/enet.h>
#include <nlohmann/json.hpp>
#include <array>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <string>
using json = nlohmann::json;

static void send(ENetPeer* peer, const json& value) {
  const auto data = value.dump();
  auto* packet = enet_packet_create(data.data(), data.size(), ENET_PACKET_FLAG_RELIABLE);
  if (!packet || enet_peer_send(peer, 0, packet)) std::abort();
}

int main(int argc, char** argv) {
  if ((argc != 2 && argc != 3) || enet_initialize()) return 2;
  const int host_count = argc - 1;
  std::array<ENetHost*, 2> hosts{};
  for (int i = 0; i < host_count; ++i) {
    const int port = std::atoi(argv[i + 1]);
    if (port < 1024 || port > 65535) return 2;
    ENetAddress address{};
    enet_address_set_host_ip(&address, "127.0.0.1");
    address.port = port;
    hosts[i] = enet_host_create(&address, 2, 3, 0, 0);
    if (!hosts[i]) return 3;
  }
  std::puts("local matchmaking fixture ready"); std::fflush(stdout);
  std::array<ENetPeer*, 2> peers{};
  std::array<unsigned, 2> ports{};
  std::array<int, 2> modes{};
  int tickets = 0;
  bool assigned = false;
  const auto start = std::chrono::steady_clock::now();
  auto assigned_at = start;
  while (std::chrono::steady_clock::now() - start < std::chrono::seconds(90)) {
    for (int host_index = 0; host_index < host_count; ++host_index) {
      ENetEvent event{};
      if (enet_host_service(hosts[host_index], &event, 50) <= 0 ||
          event.type != ENET_EVENT_TYPE_RECEIVE)
        continue;
      const auto request = json::parse(event.packet->data,
          event.packet->data + event.packet->dataLength, nullptr, false);
      enet_packet_destroy(event.packet);
      if (assigned || request.is_discarded() || !request.is_object()) return 4;
      const auto user = request.value("user", json::object());
      const auto uid = user.value("uid", "");
      const int player = uid == "offline-local-0" ? 0 : uid == "offline-local-1" ? 1 : -1;
      char ip[64]{}; enet_address_get_host_ip(&event.peer->address, ip, sizeof(ip));
      if (player < 0 || peers[player] || std::string(ip) != "127.0.0.1" ||
          request.value("type", "") != "create-ticket" ||
          user.value("playKey", "") != "not-a-real-key-" + std::to_string(player) ||
          request.value("appVersion", "") != "0.0.0-meleepad-dev") return 5;
      const int mode = request.at("search").value("mode", -1);
      if (mode != 1 && mode != 2) return 6; // Unranked/Direct fixtures only.
      peers[player] = event.peer; ports[player] = event.peer->address.port; modes[player] = mode;
      ++tickets;
      send(event.peer, {{"type", "create-ticket-resp"}, {"error", ""}});
      if (tickets == 2) {
        if (modes[0] != modes[1]) return 7;
        for (int local = 0; local < 2; ++local) {
          json players = json::array();
          for (int p = 0; p < 2; ++p) {
            const auto endpoint = "127.0.0.1:" + std::to_string(ports[p]);
            players.push_back({{"uid", "offline-local-" + std::to_string(p)},
              {"displayName", "Local fixture " + std::to_string(p)},
              {"connectCode", "TEST#" + std::to_string(p)}, {"port", p + 1},
              {"isLocalPlayer", p == local}, {"ipAddress", endpoint},
              {"ipAddressLan", endpoint}, {"chatMessages", json::array()}, {"rank", nullptr}});
          }
          send(peers[local], {{"type", "get-ticket-resp"}, {"error", ""},
            {"matchId", "offline-local-fixture"}, {"isHost", local == 0},
            {"players", players}, {"stages", {31}}, {"items", 0}});
        }
        assigned = true; assigned_at = std::chrono::steady_clock::now();
      }
      enet_host_flush(hosts[host_index]);
    }
    for (int i = 0; i < host_count; ++i)
      enet_host_flush(hosts[i]);
    if (assigned && std::chrono::steady_clock::now() - assigned_at > std::chrono::seconds(5)) break;
  }
  for (int i = 0; i < host_count; ++i)
    enet_host_destroy(hosts[i]);
  enet_deinitialize();
  std::printf("{\"tickets\":%d,\"assigned\":%s,\"mode\":%d,\"loopback_only\":true}\n",
              tickets, assigned ? "true" : "false", modes[0]);
  return assigned ? 0 : 8;
}
