// Host-only interposition for recoverable driver failures and a lost device.
#include <vortex2.h>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>

static bool fail(const char *kind) {
  const char *mode = std::getenv("CUPBOP_TEST_GRID_FAULT");
  return mode && std::getenv("CUPBOP_TEST_GRID_ARMED") && !std::strcmp(mode, kind);
}
extern "C" vx_result_t vx_buffer_create(vx_device_h d, uint64_t bytes, uint32_t flags, vx_buffer_h *out) {
  static auto real = reinterpret_cast<decltype(&vx_buffer_create)>(dlsym(RTLD_NEXT, "vx_buffer_create"));
  if (bytes == 8 && fail("alloc")) return VX_ERR_OUT_OF_DEVICE_MEMORY;
  return real(d, bytes, flags, out);
}
extern "C" vx_result_t vx_enqueue_write(vx_queue_h q, vx_buffer_h buf, uint64_t offset, const void *data,
                                        uint64_t bytes, uint32_t count, const vx_event_h *waits, vx_event_h *out) {
  static auto real = reinterpret_cast<decltype(&vx_enqueue_write)>(dlsym(RTLD_NEXT, "vx_enqueue_write"));
  if (bytes == 8 && fail("init")) return VX_ERR_INTERNAL;
  return real(q, buf, offset, data, bytes, count, waits, out);
}
static vx_event_h lost_event;
extern "C" vx_result_t vx_enqueue_launch(vx_queue_h q, const vx_launch_info_t *info, uint32_t count,
                                         const vx_event_h *waits, vx_event_h *out) {
  static auto real = reinterpret_cast<decltype(&vx_enqueue_launch)>(dlsym(RTLD_NEXT, "vx_enqueue_launch"));
  if (fail("enqueue")) return VX_ERR_INVALID_INFO;
  auto status = real(q, info, count, waits, out);
  if (status == VX_SUCCESS && fail("lost")) lost_event = *out;
  return status;
}
extern "C" vx_result_t vx_event_wait_value(vx_event_h event, uint64_t value, uint64_t timeout) {
  static auto real = reinterpret_cast<decltype(&vx_event_wait_value)>(dlsym(RTLD_NEXT, "vx_event_wait_value"));
  auto status = real(event, value, timeout);
  return status == VX_SUCCESS && fail("lost") && event == lost_event ? VX_ERR_DEVICE_LOST : status;
}
