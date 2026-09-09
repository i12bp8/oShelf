// Test-only virtual pointer. Reads: move x y, down, up, wait milliseconds.
#include <wayland-client.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "pointer.h"
static struct zwlr_virtual_pointer_manager_v1 *manager;
static void global(void *d, struct wl_registry *r, uint32_t n, const char *s, uint32_t v) {
    (void)d; (void)v;
    if (!strcmp(s, "zwlr_virtual_pointer_manager_v1"))
        manager = wl_registry_bind(r, n, &zwlr_virtual_pointer_manager_v1_interface, 1);
}
static void removed(void *d, struct wl_registry *r, uint32_t n) { (void)d; (void)r; (void)n; }
static const struct wl_registry_listener listener = {global, removed};
int main(int argc, char **argv) {
    FILE *input = argc == 2 ? fopen(argv[1], "r") : stdin;
    if (!input) return 2;
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) return 1;
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &listener, NULL);
    wl_display_roundtrip(display);
    if (!manager) return 1;
    struct zwlr_virtual_pointer_v1 *pointer = zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager, NULL);
    char line[128], command[16]; unsigned x = 0, y = 0, width = 1536, height = 864;
    while (fgets(line, sizeof(line), input)) {
        struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
        uint32_t ms = t.tv_sec * 1000 + t.tv_nsec / 1000000;
        if (sscanf(line, "%15s %u %u", command, &x, &y) < 1) break;
        if (!strcmp(command, "extent") && x && y) { width = x; height = y; }
        else if (!strcmp(command, "move")) zwlr_virtual_pointer_v1_motion_absolute(pointer, ms, x, y, width, height);
        else if (!strcmp(command, "down")) zwlr_virtual_pointer_v1_button(pointer, ms, 272, WL_POINTER_BUTTON_STATE_PRESSED);
        else if (!strcmp(command, "up")) zwlr_virtual_pointer_v1_button(pointer, ms, 272, WL_POINTER_BUTTON_STATE_RELEASED);
        else if (!strcmp(command, "wait")) usleep(x * 1000);
        zwlr_virtual_pointer_v1_frame(pointer);
        wl_display_roundtrip(display);
    }
    zwlr_virtual_pointer_v1_destroy(pointer);
    wl_display_roundtrip(display); wl_display_disconnect(display);
}
