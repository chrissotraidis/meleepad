// Synthetic Slippi transport test. Does not boot Melee or exercise rollback.
#include "Core/Slippi/SlippiNetplay.h"
#include "Core/Slippi/SlippiPremadeText.h"
#include "Common/Config/Config.h"
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <thread>

using Clock = std::chrono::steady_clock;
using namespace std::chrono_literals;

template <typename F> bool Wait(F condition, int milliseconds = 10000)
{
  const auto end = Clock::now() + std::chrono::milliseconds(milliseconds);
  while (Clock::now() < end)
  {
    if (condition()) return true;
    std::this_thread::sleep_for(2ms);
  }
  return false;
}

int main(int argc, char** argv)
{
  if (argc != 4) return 2;
  const int player = std::atoi(argv[1]);
  const auto local_port = static_cast<u16>(std::atoi(argv[2]));
  const auto remote_port = static_cast<u16>(std::atoi(argv[3]));
  if (player < 0 || player > 1 || !local_port || !remote_port) return 2;
  Config::Init();
  if (SlippiUTF8ToUTF32("Melee 日本 🎮") != U"Melee 日本 🎮") return 8;
  if (enet_initialize()) return 3;
  int received = 0;
  int mismatches = 0;
  bool disconnected = false;
  {
    SlippiNetplayClient peer({"127.0.0.1"}, {remote_port}, 1, local_port,
                             player == 0, static_cast<u8>(player));
    using Status = SlippiNetplayClient::SlippiConnectStatus;
    if (!Wait([&] { return peer.GetSlippiConnectStatus() == Status::NET_CONNECT_STATUS_CONNECTED; }))
      return 4;
    peer.StartSlippiGame();
    peer.SendConnectionSelected();
    for (s32 frame = 1; frame <= 300; ++frame)
    {
      // Deliberate send stalls test eventual delivery; these are not rollback tests.
      if (player == 1 && frame % 100 == 0) std::this_thread::sleep_for(50ms);
      u8 input[SLIPPI_PAD_DATA_SIZE];
      for (int byte = 0; byte < SLIPPI_PAD_DATA_SIZE; ++byte)
        input[byte] = static_cast<u8>(frame + byte * 17 + player * 91);
      peer.SendSlippiPad(std::make_unique<SlippiPad>(frame, frame, 0xabc00000u + frame, input));
      if (!Wait([&] {
        auto output = peer.GetSlippiRemotePad(0, 128);
        if (output->latest_frame < frame) return false;
        // Output contains newest frame first, each padded to 12 bytes by Slippi.
        const auto offset = static_cast<size_t>(output->latest_frame - frame) * SLIPPI_PAD_FULL_SIZE;
        if (offset + SLIPPI_PAD_DATA_SIZE > output->data.size()) { ++mismatches; return true; }
        for (int byte = 0; byte < SLIPPI_PAD_DATA_SIZE; ++byte)
          mismatches += output->data[offset + byte] != static_cast<u8>(frame + byte * 17 + (1-player) * 91);
        mismatches += output->player_idx != 1-player;
        mismatches += output->checksum_frame < frame;
        mismatches += output->checksum != 0xabc00000u + output->checksum_frame;
        ++received;
        return true;
      })) return 6;
      peer.DropOldRemoteInputs(frame);
    }
    // Let both processes receive the final input before intentional disconnect.
    if (player == 0)
    {
      std::this_thread::sleep_for(300ms);
      peer.ForceDisconnect(SlippiNetplayClient::SlippiDisconnectReason::POOR_PERFORMANCE);
      disconnected = true;
    }
    else
    {
      disconnected = Wait([&] {
        return peer.GetSlippiConnectStatus() == Status::NET_CONNECT_STATUS_DISCONNECTED;
      });
      mismatches += peer.GetDisconnectReason() != SlippiNetplayClient::SlippiDisconnectReason::POOR_PERFORMANCE;
    }
  }
  enet_deinitialize();
  Config::Shutdown();
  std::printf("{\"player\":%d,\"frames_received\":%d,\"mismatches\":%d,\"disconnect_pass\":%s,\"game_executed\":false}\n",
              player, received, mismatches, disconnected ? "true" : "false");
  return received == 300 && !mismatches && disconnected ? 0 : 7;
}
