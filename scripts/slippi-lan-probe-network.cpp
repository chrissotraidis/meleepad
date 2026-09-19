// Private diagnostic only. Static runtime/Rust networking is limited to UDP
// loopback and one explicitly configured RFC1918 fixture host. Not an OS sandbox.
#include <arpa/inet.h>
#include <cerrno>
#include <cstring>
#include <dlfcn.h>
#include <netdb.h>
#include <sys/socket.h>
#ifndef SLIPPI_FIXTURE_IPV4
#error Explicit private fixture IPv4 required
#endif
namespace {
bool permitted(const sockaddr* address, socklen_t length) {
  if (!address || length < sizeof(sockaddr_in) || address->sa_family != AF_INET) return false;
  const auto* v4=reinterpret_cast<const sockaddr_in*>(address);
  in_addr host{}; inet_pton(AF_INET,SLIPPI_FIXTURE_IPV4,&host);
#ifdef SLIPPI_FIXTURE_PEER_SUBNET24
  // Mac-side peer only: an explicitly enabled same-/24 LAN fixture subnet.
  const auto target=ntohl(v4->sin_addr.s_addr), fixture=ntohl(host.s_addr);
  if ((target & 0xffffff00u)==(fixture & 0xffffff00u) && (target & 255u)!=0 && (target & 255u)!=255) return true;
#endif
  return v4->sin_addr.s_addr == host.s_addr || v4->sin_addr.s_addr == htonl(INADDR_LOOPBACK);
}
template<typename T> T real(const char* name) { return reinterpret_cast<T>(dlsym(RTLD_NEXT,name)); }
}
extern "C" int socket(int domain,int type,int protocol) {
  if (domain != AF_INET || type != SOCK_DGRAM || (protocol != 0 && protocol != IPPROTO_UDP)) {errno=EPERM;return -1;}
  auto fn=real<int(*)(int,int,int)>("socket");if(!fn){errno=ENOSYS;return -1;}return fn(domain,type,protocol);
}
extern "C" int connect(int fd,const sockaddr* address,socklen_t length) {
  if(!permitted(address,length)){errno=EPERM;return -1;}
  auto fn=real<int(*)(int,const sockaddr*,socklen_t)>("connect");if(!fn){errno=ENOSYS;return -1;}return fn(fd,address,length);
}
extern "C" ssize_t sendto(int fd,const void* bytes,size_t size,int flags,const sockaddr* address,socklen_t length) {
  if(!permitted(address,length)){errno=EPERM;return -1;}
  auto fn=real<ssize_t(*)(int,const void*,size_t,int,const sockaddr*,socklen_t)>("sendto");
  if(!fn){errno=ENOSYS;return -1;}return fn(fd,bytes,size,flags,address,length);
}
extern "C" ssize_t sendmsg(int fd,const msghdr* message,int flags) {
  if(!message || !permitted(static_cast<const sockaddr*>(message->msg_name),message->msg_namelen)){errno=EPERM;return -1;}
  auto fn=real<ssize_t(*)(int,const msghdr*,int)>("sendmsg");if(!fn){errno=ENOSYS;return -1;}return fn(fd,message,flags);
}
extern "C" int getaddrinfo(const char* node,const char* service,const addrinfo* hints,addrinfo** result) {
  sockaddr_in numeric{}; numeric.sin_family=AF_INET;
  if(!node || inet_pton(AF_INET,node,&numeric.sin_addr)!=1 || !permitted(reinterpret_cast<sockaddr*>(&numeric),sizeof(numeric))) {
    if(result)*result=nullptr;return EAI_NONAME;
  }
  addrinfo numeric_hints=hints ? *hints : addrinfo{};
  numeric_hints.ai_family=AF_INET; numeric_hints.ai_flags |= AI_NUMERICHOST;
  auto fn=real<int(*)(const char*,const char*,const addrinfo*,addrinfo**)>("getaddrinfo");
  if(!fn)return EAI_SYSTEM;return fn(node,service,&numeric_hints,result);
}
