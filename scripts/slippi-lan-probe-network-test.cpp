#include <arpa/inet.h>
#include <cerrno>
#include <cstdio>
#include <netdb.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>
int main() {
 int checks=0,failures=0;auto check=[&](bool ok){++checks;if(!ok){++failures;std::fprintf(stderr,"failed check %d errno=%d\n",checks,errno);}};
 check(socket(AF_INET,SOCK_STREAM,0)==-1 && errno==EPERM);
 check(socket(AF_INET6,SOCK_DGRAM,0)==-1 && errno==EPERM);
 int receiver=socket(AF_INET,SOCK_DGRAM,0), sender=socket(AF_INET,SOCK_DGRAM,0);check(receiver>=0 && sender>=0);
 sockaddr_in local{};local.sin_family=AF_INET;local.sin_addr.s_addr=htonl(INADDR_LOOPBACK);
 check(bind(receiver,reinterpret_cast<sockaddr*>(&local),sizeof(local))==0);
 socklen_t size=sizeof(local);getsockname(receiver,reinterpret_cast<sockaddr*>(&local),&size);
 check(sendto(sender,"x",1,0,reinterpret_cast<sockaddr*>(&local),sizeof(local))==1);
 char byte=0;auto receive=[&](){pollfd fd{receiver,POLLIN,0};return poll(&fd,1,1000)==1 ? recv(receiver,&byte,1,MSG_DONTWAIT) : -1;};check(receive()==1 && byte=='x');
 sockaddr_in remote=local;inet_pton(AF_INET,"192.0.2.1",&remote.sin_addr);
 check(sendto(sender,"x",1,0,reinterpret_cast<sockaddr*>(&remote),sizeof(remote))==-1 && errno==EPERM);
 check(connect(sender,reinterpret_cast<sockaddr*>(&remote),sizeof(remote))==-1 && errno==EPERM);
 iovec io{&byte,1};msghdr msg{};msg.msg_name=&remote;msg.msg_namelen=sizeof(remote);msg.msg_iov=&io;msg.msg_iovlen=1;
 check(sendmsg(sender,&msg,0)==-1 && errno==EPERM);
 msg.msg_name=&local;check(sendmsg(sender,&msg,0)==1);check(receive()==1);
 addrinfo* info=nullptr;check(getaddrinfo("example.com",nullptr,nullptr,&info)==EAI_NONAME && info==nullptr);
 check(getaddrinfo("127.0.0.1",nullptr,nullptr,&info)==0);if(info)freeaddrinfo(info);
 info=nullptr;check(getaddrinfo("192.0.2.1",nullptr,nullptr,&info)==EAI_NONAME && info==nullptr);
#ifdef SLIPPI_FIXTURE_TEST_PEER_IPV4
 info=nullptr;
#ifdef SLIPPI_FIXTURE_PEER_SUBNET24
 check(getaddrinfo(SLIPPI_FIXTURE_TEST_PEER_IPV4,nullptr,nullptr,&info)==0);if(info)freeaddrinfo(info);
#else
 check(getaddrinfo(SLIPPI_FIXTURE_TEST_PEER_IPV4,nullptr,nullptr,&info)==EAI_NONAME && info==nullptr);
#endif
#endif
 close(sender);close(receiver);
 std::printf("{\"checks\":%d,\"failures\":%d,\"loopback_udp_executed\":true,\"outside_destination_denied\":true}\n",checks,failures);return failures?1:0;
}
