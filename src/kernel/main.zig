const lib = @import("lib.zig");

pub fn main() void {
    const console_out = lib.uefi.system_table.con_out.?;
    _ = console_out.reset(true);
    _ = console_out.clearScreen();
    _ = console_out.outputString(lib.utf16("Hello World!!\r\n"));
    const boot_services = lib.uefi.system_table.boot_services.?;

    var gop: *lib.uefi.protocol.GraphicsOutput = undefined;
    var status = boot_services.locateProtocol(&lib.uefi.protocol.GraphicsOutput.guid, null, @as(*?*anyopaque, @ptrCast(&gop)));
    if (status != lib.uefi.Status.Success) {
        _ = console_out.outputString(lib.utf16("No GOP!\r\n"));
        lib.hang();
    }
    _ = console_out.outputString(lib.utf16("Has GOP!\r\n"));
    {
        //TODO: query mode 0 and check to make sure that mode 0 works
        status = gop.setMode(0);
        if (status != lib.uefi.Status.Success) {
            _ = console_out.outputString(lib.utf16("Set mode 0 failed!\r\n"));
            lib.hang();
        }
    }

    //var screen_width: usize = gop.mode.info.horizontal_resolution;
    //var screen_height: usize = gop.mode.info.vertical_resolution;
    const frame_buffer_address: u64 = gop.mode.frame_buffer_base;
    const frame_buffer_len: usize = gop.mode.frame_buffer_size;

    //TODO dynamically allocate memory descriptors with allocatePool() to guarantee that the array to hold them is big enough
    var memory_descriptors: [64]lib.uefi.tables.MemoryDescriptor = undefined;
    var mmap_size = memory_descriptors.len * @sizeOf(lib.uefi.tables.MemoryDescriptor);
    var map_key: usize = 0;
    var descriptor_size: usize = 0;
    var descriptor_version: u32 = 0;
    status = boot_services.getMemoryMap(&mmap_size, &memory_descriptors, &map_key, &descriptor_size, &descriptor_version);
    if (status != lib.uefi.Status.Success) {
        _ = console_out.outputString(lib.utf16("Get memory map failed!\r\n"));
        lib.hang();
    }

    status = boot_services.exitBootServices(lib.uefi.handle, map_key);
    if (status != lib.uefi.Status.Success) {
        _ = console_out.outputString(lib.utf16("Exit boot services failed!\r\n"));
        lib.hang();
    }

    //TODO check the pixel format of the frame buffer. assuming xRGB (blue is LSB) for now.
    const frame_buffer: []volatile u32 = @as([*]volatile u32, @ptrFromInt(frame_buffer_address))[0 .. frame_buffer_len / 4];
    for (frame_buffer) |*px| {
        px.* = 0x00FF0000;
    }

    lib.hang();
}
