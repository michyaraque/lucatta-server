#ifndef FS_WEBSOCKET_H
#define FS_WEBSOCKET_H

#include <string_view>

namespace tfs::ws {

void start(bool bindOnlyOtsIP, std::string_view otsIP, unsigned short port = 0, int threads = 1);
void stop();

} // namespace tfs::ws

#endif // FS_WEBSOCKET_H
