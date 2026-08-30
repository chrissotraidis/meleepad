#include <libproc.h>
#include <mach/arm/thread_status.h>
#include <mach/mach.h>
#include <signal.h>
#include <sys/proc_info.h>

#include <algorithm>
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
  std::uint64_t unix_ns;
  std::uint64_t cpu_ns;
  std::uint64_t native_pc;
  std::uint64_t pc_read_ns;
  int state;
  int sleep_seconds;
};

struct ImageInfo
{
  std::uint64_t base = 0;
  std::uint64_t size = 0;
  std::string path;
};

struct PhaseColumns
{
  std::size_t emulated_frame;
  std::size_t trigger_metric;
  std::size_t host_frame_end_unix_ns;
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

std::uint64_t FindHottestThread(int pid, proc_threadinfo* found)
{
  std::vector<std::uint64_t> handles(2048);
  const int bytes = proc_pidinfo(pid, PROC_PIDLISTTHREADS, 0, handles.data(),
                                 static_cast<int>(handles.size() * sizeof(handles[0])));
  if (bytes <= 0)
    return 0;
  handles.resize(static_cast<std::size_t>(bytes) / sizeof(handles[0]));

  std::vector<std::uint64_t> initial_cpu(handles.size(), 0);
  for (std::size_t index = 0; index < handles.size(); ++index)
  {
    proc_threadinfo info{};
    if (ReadThread(pid, handles[index], &info))
      initial_cpu[index] = info.pth_user_time + info.pth_system_time;
  }
  std::this_thread::sleep_for(std::chrono::milliseconds(100));

  std::uint64_t hottest_handle = 0;
  std::uint64_t hottest_delta = 0;
  for (std::size_t index = 0; index < handles.size(); ++index)
  {
    proc_threadinfo info{};
    if (!ReadThread(pid, handles[index], &info))
      continue;
    const std::uint64_t current_cpu = info.pth_user_time + info.pth_system_time;
    const std::uint64_t delta = current_cpu >= initial_cpu[index] ?
                                    current_cpu - initial_cpu[index] :
                                    0;
    if (delta > hottest_delta)
    {
      hottest_delta = delta;
      hottest_handle = handles[index];
      *found = info;
    }
  }
  if (hottest_handle != 0)
    std::cerr << "selected hottest thread handle=" << hottest_handle
              << " delta_ns=" << hottest_delta << " name="
              << (found->pth_name[0] == '\0' ? "<unnamed>" : found->pth_name) << '\n';
  return hottest_handle;
}

void PrintThreadNames(int pid)
{
  std::vector<std::uint64_t> handles(2048);
  const int bytes = proc_pidinfo(pid, PROC_PIDLISTTHREADS, 0, handles.data(),
                                 static_cast<int>(handles.size() * sizeof(handles[0])));
  if (bytes <= 0)
    return;
  handles.resize(static_cast<std::size_t>(bytes) / sizeof(handles[0]));
  std::cerr << "available threads:\n";
  for (const std::uint64_t handle : handles)
  {
    proc_threadinfo info{};
    if (ReadThread(pid, handle, &info))
      std::cerr << "  handle=" << handle << " name="
                << (info.pth_name[0] == '\0' ? "<unnamed>" : info.pth_name) << '\n';
  }
}

thread_t FindMachThread(task_t task, std::uint64_t thread_handle)
{
  thread_act_array_t threads = nullptr;
  mach_msg_type_number_t count = 0;
  if (task_threads(task, &threads, &count) != KERN_SUCCESS)
    return MACH_PORT_NULL;

  thread_t found = MACH_PORT_NULL;
  for (mach_msg_type_number_t index = 0; index < count; ++index)
  {
    thread_identifier_info_data_t identifier{};
    mach_msg_type_number_t identifier_count = THREAD_IDENTIFIER_INFO_COUNT;
    if (thread_info(threads[index], THREAD_IDENTIFIER_INFO,
                    reinterpret_cast<thread_info_t>(&identifier),
                    &identifier_count) == KERN_SUCCESS &&
        identifier.thread_handle == thread_handle)
    {
      found = threads[index];
    }
    else
    {
      mach_port_deallocate(mach_task_self(), threads[index]);
    }
  }
  vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(threads),
                count * sizeof(thread_t));
  return found;
}

bool ReadNativePc(thread_t thread, std::uint64_t* pc)
{
  arm_thread_state64_t state{};
  mach_msg_type_number_t count = ARM_THREAD_STATE64_COUNT;
  if (thread_get_state(thread, ARM_THREAD_STATE64, reinterpret_cast<thread_state_t>(&state),
                       &count) != KERN_SUCCESS)
    return false;
  *pc = arm_thread_state64_get_pc(state);
  return true;
}

ImageInfo ResolveImage(int pid, std::uint64_t pc)
{
  proc_regionwithpathinfo region{};
  if (pc == 0 || proc_pidinfo(pid, PROC_PIDREGIONPATHINFO, pc, &region, sizeof(region)) !=
                     sizeof(region))
    return {};
  return {region.prp_prinfo.pri_address, region.prp_prinfo.pri_size,
          region.prp_vip.vip_path};
}

ImageInfo ResolveImageCached(int pid, std::uint64_t pc, std::vector<ImageInfo>* cache)
{
  for (const ImageInfo& image : *cache)
  {
    if (pc >= image.base && pc - image.base < image.size)
      return image;
  }
  const ImageInfo image = ResolveImage(pid, pc);
  if (image.size != 0)
    cache->push_back(image);
  return image;
}

std::string CsvEscape(const std::string& value)
{
  if (value.find_first_of(",\"\r\n") == std::string::npos)
    return value;
  std::string escaped = "\"";
  for (const char character : value)
  {
    if (character == '\"')
      escaped += '\"';
    escaped += character;
  }
  escaped += '\"';
  return escaped;
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

bool ParsePhaseHeader(const std::string& line, const std::string& trigger_metric_name,
                      PhaseColumns* columns)
{
  const std::vector<std::string> fields = SplitCsv(line);
  columns->emulated_frame = fields.size();
  columns->trigger_metric = fields.size();
  columns->host_frame_end_unix_ns = fields.size();
  for (std::size_t index = 0; index < fields.size(); ++index)
  {
    if (fields[index] == "emulated_frame")
      columns->emulated_frame = index;
    else if (fields[index] == trigger_metric_name)
      columns->trigger_metric = index;
    else if (fields[index] == "host_frame_end_unix_ns")
      columns->host_frame_end_unix_ns = index;
  }
  return columns->emulated_frame < fields.size() && columns->trigger_metric < fields.size();
}

bool ParsePhase(const std::string& line, const PhaseColumns& columns,
                std::uint64_t* emulated_frame, double* trigger_metric_ms,
                std::uint64_t* host_frame_end_unix_ns)
{
  const std::vector<std::string> fields = SplitCsv(line);
  if (columns.emulated_frame >= fields.size() || columns.trigger_metric >= fields.size() ||
      (host_frame_end_unix_ns && columns.host_frame_end_unix_ns >= fields.size()))
    return false;
  try
  {
    std::size_t emulated_parsed = 0;
    std::size_t metric_parsed = 0;
    *emulated_frame = std::stoull(fields[columns.emulated_frame], &emulated_parsed);
    *trigger_metric_ms = std::stod(fields[columns.trigger_metric], &metric_parsed);
    if (emulated_parsed != fields[columns.emulated_frame].size() ||
        metric_parsed != fields[columns.trigger_metric].size())
      return false;
    if (host_frame_end_unix_ns)
    {
      std::size_t host_parsed = 0;
      *host_frame_end_unix_ns =
          std::stoull(fields[columns.host_frame_end_unix_ns], &host_parsed);
      if (host_parsed != fields[columns.host_frame_end_unix_ns].size())
        return false;
    }
    return true;
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
  if (argc == 3 && std::string(argv[2]) == "--list-threads")
  {
    const int pid = std::atoi(argv[1]);
    if (pid <= 0 || kill(pid, 0) != 0)
      return 2;
    PrintThreadNames(pid);
    return 0;
  }
  if (argc < 10 || argc > 12)
  {
    std::cerr << "usage: sampler pid thread-substring phase.csv min-emu max-emu threshold-ms "
                 "interval-us max-seconds output.csv [native-pc [trigger-column]]\n";
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
  const bool sample_native_pc = argc >= 11 && std::string(argv[10]) == "native-pc";
  const std::string trigger_metric_name = argc == 12 ? argv[11] : "total_ms";
  if (pid <= 0 || needle.empty() || min_emu >= max_emu || threshold_ms <= 0 || interval_us <= 0 ||
      max_seconds <= 0 || (argc >= 11 && !sample_native_pc) || trigger_metric_name.empty())
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
  if (!ParsePhaseHeader(phase_header, trigger_metric_name, &phase_columns))
  {
    std::cerr << "phase header missing emulated_frame or " << trigger_metric_name << '\n';
    return 2;
  }
  if (sample_native_pc && phase_columns.host_frame_end_unix_ns == SplitCsv(phase_header).size())
  {
    std::cerr << "native-pc mode requires host_frame_end_unix_ns\n";
    return 2;
  }

  proc_threadinfo first{};
  std::uint64_t tid = 0;
  for (int attempt = 0; attempt < 500 && tid == 0; ++attempt)
  {
    tid = needle == "@hottest" ? FindHottestThread(pid, &first) : FindThread(pid, needle, &first);
    if (tid == 0)
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  if (tid == 0)
  {
    std::cerr << "matching thread not found\n";
    PrintThreadNames(pid);
    return 1;
  }

  task_t task = MACH_PORT_NULL;
  thread_t mach_thread = MACH_PORT_NULL;
  if (sample_native_pc)
  {
    const kern_return_t task_result = task_for_pid(mach_task_self(), pid, &task);
    if (task_result != KERN_SUCCESS)
    {
      std::cerr << "task_for_pid failed: " << task_result
                << " (target must be signed with get-task-allow)\n";
      return 4;
    }
    mach_thread = FindMachThread(task, tid);
    if (mach_thread == MACH_PORT_NULL)
    {
      std::cerr << "matching Mach thread not found\n";
      mach_port_deallocate(mach_task_self(), task);
      return 4;
    }
  }

  const std::size_t ring_capacity =
      static_cast<std::size_t>((sample_native_pc ?
                                    static_cast<std::uint64_t>(max_seconds) * 1'000'000ULL :
                                    3'000'000ULL) /
                               interval_us) +
      1;
  const int post_target = 300'000 / interval_us + 1;
  std::deque<Sample> ring;
  bool triggered = false;
  int post_remaining = 0;
  std::uint64_t trigger_wall_ns = 0;
  std::uint64_t trigger_emu = 0;
  std::uint64_t trigger_host_ns = 0;
  double trigger_metric_ms = 0;
  std::uint64_t samples = 0;
  std::uint64_t errors = 0;
  std::uint64_t pc_read_total_ns = 0;
  std::uint64_t pc_read_worst_ns = 0;
  std::uint64_t pc_reads = 0;
  const auto start = std::chrono::steady_clock::now();
  const auto unix_start = std::chrono::system_clock::now();
  const std::uint64_t unix_start_ns = static_cast<std::uint64_t>(
      std::chrono::duration_cast<std::chrono::nanoseconds>(unix_start.time_since_epoch()).count());
  const auto deadline = start + std::chrono::seconds(max_seconds);

  std::cout << "pid=" << pid << " tid=" << tid << " name=" << first.pth_name << '\n';
  while (std::chrono::steady_clock::now() < deadline && kill(pid, 0) == 0)
  {
    const auto now = std::chrono::steady_clock::now();
    proc_threadinfo info{};
    if (ReadThread(pid, tid, &info))
    {
      const std::uint64_t wall_ns = static_cast<std::uint64_t>(
          std::chrono::duration_cast<std::chrono::nanoseconds>(now - start).count());
      std::uint64_t native_pc = 0;
      std::uint64_t pc_read_ns = 0;
      const auto pc_read_start = std::chrono::steady_clock::now();
      const bool pc_ok = !sample_native_pc || ReadNativePc(mach_thread, &native_pc);
      if (sample_native_pc)
      {
        pc_read_ns = static_cast<std::uint64_t>(std::chrono::duration_cast<std::chrono::nanoseconds>(
                                                    std::chrono::steady_clock::now() - pc_read_start)
                                                    .count());
        pc_read_total_ns += pc_read_ns;
        pc_read_worst_ns = std::max(pc_read_worst_ns, pc_read_ns);
        ++pc_reads;
      }
      if (pc_ok)
      {
        ring.push_back({wall_ns, unix_start_ns + wall_ns,
                        info.pth_user_time + info.pth_system_time, native_pc, pc_read_ns,
                        info.pth_run_state, info.pth_sleep_time});
        if (ring.size() > ring_capacity)
          ring.pop_front();
      }
      else
      {
        ++errors;
      }
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
          ParsePhase(line, phase_columns, &trigger_emu, &trigger_metric_ms,
                     sample_native_pc ? &trigger_host_ns : nullptr) &&
          trigger_emu >= min_emu && trigger_emu < max_emu && trigger_metric_ms > threshold_ms)
      {
        constexpr std::uint64_t freshness_slack_ns = 1'000'000'000;
        const std::uint64_t earliest_host_ns =
            unix_start_ns > freshness_slack_ns ? unix_start_ns - freshness_slack_ns : 0;
        if (!sample_native_pc || trigger_host_ns >= earliest_host_ns)
        {
          triggered = true;
          post_remaining = post_target;
          trigger_wall_ns = ring.empty() ? 0 : ring.back().wall_ns;
        }
      }
    }
    if (triggered && --post_remaining <= 0)
      break;
    std::this_thread::sleep_for(std::chrono::microseconds(interval_us));
  }

  if (!triggered && !sample_native_pc)
  {
    std::cerr << "no phase trigger samples=" << samples << " errors=" << errors << '\n';
    if (mach_thread != MACH_PORT_NULL)
      mach_port_deallocate(mach_task_self(), mach_thread);
    if (task != MACH_PORT_NULL)
      mach_port_deallocate(mach_task_self(), task);
    return 3;
  }
  std::ofstream output(output_path);
  if (!output)
    return 1;
  output << "wall_ns,unix_ns,cpu_ns,state,sleep_seconds,native_pc,pc_read_ns,image_base,"
            "image_offset,image_path\n";
  std::vector<ImageInfo> image_cache;
  for (const Sample& sample : ring)
  {
    const ImageInfo image = ResolveImageCached(pid, sample.native_pc, &image_cache);
    output << sample.wall_ns << ',' << sample.unix_ns << ',' << sample.cpu_ns << ','
           << sample.state << ',' << sample.sleep_seconds << ',' << sample.native_pc << ','
           << sample.pc_read_ns << ',' << image.base << ','
           << (sample.native_pc >= image.base ? sample.native_pc - image.base : 0) << ','
           << CsvEscape(image.path) << '\n';
  }
  if (mach_thread != MACH_PORT_NULL)
    mach_port_deallocate(mach_task_self(), mach_thread);
  if (task != MACH_PORT_NULL)
    mach_port_deallocate(mach_task_self(), task);
  if (!triggered)
  {
    std::cerr << "no phase trigger samples=" << samples << " retained=" << ring.size()
              << " errors=" << errors << '\n';
    return 3;
  }
  std::cout << "trigger_emu=" << trigger_emu << " trigger_metric=" << trigger_metric_name
            << " trigger_metric_ms=" << trigger_metric_ms << " trigger_host_ns="
            << trigger_host_ns << " trigger_wall_ns=" << trigger_wall_ns << " samples=" << samples
            << " retained=" << ring.size() << " errors=" << errors;
  if (pc_reads != 0)
    std::cout << " pc_read_mean_ns=" << pc_read_total_ns / pc_reads
              << " pc_read_worst_ns=" << pc_read_worst_ns;
  std::cout << '\n';
  return errors == 0 ? 0 : 1;
}
