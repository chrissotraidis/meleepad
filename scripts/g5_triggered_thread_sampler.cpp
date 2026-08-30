#include <libproc.h>
#include <signal.h>
#include <sys/proc_info.h>

#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <deque>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace
{
struct Sample
{
  std::uint64_t wall_ns;
  std::uint64_t cpu_ns;
  int state;
  int sleep_seconds;
};

struct PhaseColumns
{
  std::size_t emulated_frame;
  std::size_t total_ms;
};

bool ReadThread(int pid, std::uint64_t tid, proc_threadinfo* info)
{
  return proc_pidinfo(pid, PROC_PIDTHREADINFO, tid, info, sizeof(*info)) == sizeof(*info);
}

std::uint64_t FindThread(int pid, const std::string& needle, proc_threadinfo* found)
{
  std::vector<std::uint64_t> tids(2048);
  const int bytes = proc_pidinfo(pid, PROC_PIDLISTTHREADS, 0, tids.data(),
                                 static_cast<int>(tids.size() * sizeof(tids[0])));
  if (bytes <= 0)
    return 0;
  tids.resize(static_cast<std::size_t>(bytes) / sizeof(tids[0]));
  for (std::uint64_t tid : tids)
  {
    proc_threadinfo info{};
    if (ReadThread(pid, tid, &info) && std::string(info.pth_name).find(needle) != std::string::npos)
    {
      *found = info;
      return tid;
    }
  }
  return 0;
}

std::vector<std::string> SplitCsv(const std::string& line)
{
  std::vector<std::string> fields;
  std::size_t begin = 0;
  while (true)
  {
    const std::size_t end = line.find(',', begin);
    fields.push_back(line.substr(begin, end == std::string::npos ? end : end - begin));
    if (end == std::string::npos)
      break;
    begin = end + 1;
  }
  if (!fields.empty() && !fields.back().empty() && fields.back().back() == '\r')
    fields.back().pop_back();
  return fields;
}

bool ParsePhaseHeader(const std::string& line, PhaseColumns* columns)
{
  const std::vector<std::string> fields = SplitCsv(line);
  columns->emulated_frame = fields.size();
  columns->total_ms = fields.size();
  for (std::size_t index = 0; index < fields.size(); ++index)
  {
    if (fields[index] == "emulated_frame")
      columns->emulated_frame = index;
    else if (fields[index] == "total_ms")
      columns->total_ms = index;
  }
  return columns->emulated_frame < fields.size() && columns->total_ms < fields.size();
}

bool ParsePhase(const std::string& line, const PhaseColumns& columns,
                std::uint64_t* emulated_frame, double* total_ms)
{
  const std::vector<std::string> fields = SplitCsv(line);
  if (columns.emulated_frame >= fields.size() || columns.total_ms >= fields.size())
    return false;
  try
  {
    std::size_t emulated_parsed = 0;
    std::size_t total_parsed = 0;
    *emulated_frame = std::stoull(fields[columns.emulated_frame], &emulated_parsed);
    *total_ms = std::stod(fields[columns.total_ms], &total_parsed);
    return emulated_parsed == fields[columns.emulated_frame].size() &&
           total_parsed == fields[columns.total_ms].size();
  }
  catch (...)
  {
    return false;
  }
}

bool ReadFirstLine(const std::string& path, std::string* line)
{
  std::ifstream input(path);
  return static_cast<bool>(std::getline(input, *line)) && !line->empty();
}

bool ReadLastLine(const std::string& path, std::string* line)
{
  std::ifstream input(path, std::ios::binary);
  if (!input)
    return false;
  input.seekg(0, std::ios::end);
  std::streamoff position = input.tellg();
  if (position <= 0)
    return false;
  --position;
  char value = 0;
  input.seekg(position);
  input.get(value);
  if (value == '\n' && position > 0)
    --position;
  while (position > 0)
  {
    input.seekg(position);
    input.get(value);
    if (value == '\n')
    {
      ++position;
      break;
    }
    --position;
  }
  input.seekg(position);
  return static_cast<bool>(std::getline(input, *line)) && !line->empty();
}
}  // namespace

int main(int argc, char** argv)
{
  if (argc != 10)
  {
    std::cerr << "usage: sampler pid thread-substring phase.csv min-emu max-emu threshold-ms "
                 "interval-us max-seconds output.csv\n";
    return 2;
  }
  const int pid = std::atoi(argv[1]);
  const std::string needle = argv[2];
  const std::string phase_path = argv[3];
  const std::uint64_t min_emu = std::strtoull(argv[4], nullptr, 10);
  const std::uint64_t max_emu = std::strtoull(argv[5], nullptr, 10);
  const double threshold_ms = std::strtod(argv[6], nullptr);
  const int interval_us = std::atoi(argv[7]);
  const int max_seconds = std::atoi(argv[8]);
  const std::string output_path = argv[9];
  if (pid <= 0 || needle.empty() || min_emu >= max_emu || threshold_ms <= 0 || interval_us <= 0 ||
      max_seconds <= 0)
    return 2;

  std::string phase_header;
  for (int attempt = 0; attempt < 500 && phase_header.empty(); ++attempt)
  {
    ReadFirstLine(phase_path, &phase_header);
    if (phase_header.empty())
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  if (phase_header.empty())
  {
    std::cerr << "phase header not found\n";
    return 1;
  }
  PhaseColumns phase_columns{};
  if (!ParsePhaseHeader(phase_header, &phase_columns))
  {
    std::cerr << "phase header missing emulated_frame or total_ms\n";
    return 2;
  }

  proc_threadinfo first{};
  std::uint64_t tid = 0;
  for (int attempt = 0; attempt < 500 && tid == 0; ++attempt)
  {
    tid = FindThread(pid, needle, &first);
    if (tid == 0)
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  if (tid == 0)
  {
    std::cerr << "matching thread not found\n";
    return 1;
  }

  const std::size_t ring_capacity = static_cast<std::size_t>(3'000'000 / interval_us) + 1;
  const int post_target = 300'000 / interval_us + 1;
  std::deque<Sample> ring;
  bool triggered = false;
  int post_remaining = 0;
  std::uint64_t trigger_wall_ns = 0;
  std::uint64_t trigger_emu = 0;
  double trigger_total_ms = 0;
  std::uint64_t samples = 0;
  std::uint64_t errors = 0;
  const auto start = std::chrono::steady_clock::now();
  const auto deadline = start + std::chrono::seconds(max_seconds);

  std::cout << "pid=" << pid << " tid=" << tid << " name=" << first.pth_name << '\n';
  while (std::chrono::steady_clock::now() < deadline && kill(pid, 0) == 0)
  {
    const auto now = std::chrono::steady_clock::now();
    proc_threadinfo info{};
    if (ReadThread(pid, tid, &info))
    {
      ring.push_back({static_cast<std::uint64_t>(
                          std::chrono::duration_cast<std::chrono::nanoseconds>(now - start).count()),
                      info.pth_user_time + info.pth_system_time, info.pth_run_state,
                      info.pth_sleep_time});
      if (ring.size() > ring_capacity)
        ring.pop_front();
    }
    else
    {
      ++errors;
    }
    ++samples;

    if (!triggered && samples % 32 == 0)
    {
      std::string line;
      if (ReadLastLine(phase_path, &line) &&
          ParsePhase(line, phase_columns, &trigger_emu, &trigger_total_ms) &&
          trigger_emu >= min_emu && trigger_emu < max_emu && trigger_total_ms > threshold_ms)
      {
        triggered = true;
        post_remaining = post_target;
        trigger_wall_ns = ring.empty() ? 0 : ring.back().wall_ns;
      }
    }
    if (triggered && --post_remaining <= 0)
      break;
    std::this_thread::sleep_for(std::chrono::microseconds(interval_us));
  }

  if (!triggered)
  {
    std::cerr << "no phase trigger samples=" << samples << " errors=" << errors << '\n';
    return 3;
  }
  std::ofstream output(output_path);
  if (!output)
    return 1;
  output << "wall_ns,cpu_ns,state,sleep_seconds\n";
  for (const Sample& sample : ring)
    output << sample.wall_ns << ',' << sample.cpu_ns << ',' << sample.state << ','
           << sample.sleep_seconds << '\n';
  std::cout << "trigger_emu=" << trigger_emu << " trigger_total_ms=" << trigger_total_ms
            << " trigger_wall_ns=" << trigger_wall_ns << " samples=" << samples
            << " retained=" << ring.size() << " errors=" << errors << '\n';
  return errors == 0 ? 0 : 1;
}
