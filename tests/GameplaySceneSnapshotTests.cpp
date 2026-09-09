#include "Common/GameplaySceneSnapshot.h"
#include <cassert>
#include <chrono>
#include <future>
#include <thread>
#include <string_view>

using Common::GameplayScene::Recorder;
int main()
{
  {
    Common::GameplayScene::Session session(2);
    Common::GameplayScene::recorder.RecordFrame([](auto) {
      return std::optional<std::uint32_t>(0x02020002);
    });
    assert(Common::GameplayScene::recorder.Read().valid);
  }
  assert(!Common::GameplayScene::recorder.Read().valid);
  [] { Common::GameplayScene::Session session(0); return; }();
  assert(Common::GameplayScene::recorder.Read().revision == -1);
  Recorder r;
  int reads = 0;
  auto word = [&](std::uint32_t address) -> std::optional<std::uint32_t> {
    assert(address == 0x80479D30);
    ++reads;
    return 0x02020102;
  };
  r.RecordFrame(word);
  assert(reads == 0 && !r.Read().valid);
  r.Configure(1);
  r.RecordFrame(word);
  assert(reads == 0 && r.Read().revision == -1);
  r.Configure(2);
  r.RecordFrame(word);
  auto s = r.Read();
  assert(s.valid && s.frames == 1 && s.transitions == 0 && s.revision == 2);
  assert(std::string_view(Common::GameplayScene::Label(s)) == "vs-combat");
  r.RecordFrame([](auto) { return std::optional<std::uint32_t>(0x02020002); });
  assert(r.Read().transitions == 0); // previous mode changed, scene did not
  r.RecordFrame([](auto) { return std::optional<std::uint32_t>(0x02020204); });
  assert(r.Read().transitions == 1);
  assert(std::string_view(Common::GameplayScene::Label(r.Read())) == "vs-results");
  r.RecordFrame([](auto) { return std::optional<std::uint32_t>{}; });
  assert(!r.Read().valid && r.Read().transitions == 2);
  r.RecordFrame(word);
  assert(r.Read().valid && r.Read().transitions == 3);
  auto previous_session = r.Read().session;
  r.Configure(0);
  assert(!r.Read().valid && r.Read().frames == 0 && r.Read().session > previous_session);
  r.RecordFrame([](auto address) {
    assert(address == 0x80477D68);
    return std::optional<std::uint32_t>(0x02020203);
  });
  assert(std::string_view(Common::GameplayScene::Label(r.Read())) == "vs-sudden-death");
  r.Configure(-1);
  r.RecordFrame(word);
  assert(!r.Read().valid && r.Read().frames == 0);

  r.Configure(2);
  std::promise<void> locked, release;
  auto release_future = release.get_future();
  std::thread holder([&] { r.RecordFrame([&](auto) {
    locked.set_value();
    release_future.wait();
    return std::optional<std::uint32_t>(0x02020002);
  }); });
  locked.get_future().wait();
  auto skipped = std::async(std::launch::async, [&] { r.RecordFrame(word); });
  assert(skipped.wait_for(std::chrono::seconds(1)) == std::future_status::ready);
  release.set_value();
  holder.join();
  skipped.get();
  assert(r.Read().frames == 1); // producer never waits on contention

  std::atomic<bool> done{false};
  std::thread producer([&] {
    for (unsigned i = 0; i < 100000; ++i)
      r.RecordFrame([&](auto) { return std::optional<std::uint32_t>(0x02020002 + i % 2); });
    done = true;
  });
  do {
    auto snapshot = r.Read();
    assert(snapshot.valid && snapshot.revision == 2);
    assert(snapshot.routing == 0x02020002 || snapshot.routing == 0x02020003);
    assert(snapshot.transitions < snapshot.frames);
  } while (!done);
  producer.join();
  return 0;
}
