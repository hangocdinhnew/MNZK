pub const std = @import("std");
pub const utf16 = std.unicode.utf8ToUtf16LeStringLiteral;
pub const uefi = std.os.uefi;

pub fn hang() void {
    while (true) {
        asm volatile ("pause");
    }
}
