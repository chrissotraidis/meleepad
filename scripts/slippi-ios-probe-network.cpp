// Only linked into the account-free iOS diagnostic executable. Statically
// linked runtime/Rust POSIX socket and DNS requests fail before leaving the app.
// This is not an OS sandbox or an adapter for production Slippi networking.
#include <cerrno>
#include <netdb.h>
#include <sys/socket.h>

extern "C" int socket(int, int, int) {
  errno = EPERM;
  return -1;
}

extern "C" int getaddrinfo(const char*, const char*, const struct addrinfo*, struct addrinfo** result) {
  if (result) *result = nullptr;
  errno = EPERM;
  return EAI_SYSTEM;
}
