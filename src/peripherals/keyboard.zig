const std = @import("std");
const cpu = @import("../cpu.zig");
const arch = @import("arch");

pub const Keyboard = struct {
    pub const Self = @This();
    pub const Len: u4 = 4;
    pub const MOD: u4 = 0;
    pub const CHAR: u4 = 1;
    pub const CODE: u4 = 2;

    modifiers: u16,
    character: u8,
    keycode: u16,
    charmode: bool,

    comptime base: u4 = 0xc,
    interrupt_controller: *cpu.InterruptController,

    pub fn init(comptime base_addr: u4, irq: *cpu.InterruptController) Keyboard {
        return Keyboard{
            .modifiers = 0,
            .character = 0,
            .keycode = 0,
            .charmode = true,

            .base = base_addr,
            .interrupt_controller = irq,
        };
    }

    pub fn write(self: *Self, address: u4, data: u8) void {
        // writing to the keyboard is a NOP
        if (address == self.base + 0) {
            self.charmode = if (data == 1) false else true;
        }
        return;
    }

    pub fn read(self: *Self, address: u4) u8 {
        return switch (address) {
            (self.base + MOD) => @as(u8, @truncate(self.modifiers)),
            (self.base + CHAR) => self.character,
            (self.base + CODE) => @as(u8, @truncate(self.keycode >> 8)),
            (self.base + CODE + 1) => @as(u8, @truncate(self.keycode & 0xff)),
            else => 0,
        };
    }

    pub fn character_in(self: *Self, c: u8) void {
        self.character = c;
        //std.debug.print("key: {x}\n", .{c});
        if (self.charmode) {
            self.interrupt_controller.set(true, 4, @intFromEnum(arch.Interrupt.KeyboardCharacter));
        }
    }

    pub fn keyboard_in(self: *Self, key: u16, mod: u16) void {
        //std.debug.print("key: {x}, mod: {x}\n", .{key, mod});
        self.keycode = key;
        self.modifiers = mod;
        if (self.keycode == 290) {
            self.interrupt_controller.restart();
        }
        if (self.keycode == 291) {
            self.interrupt_controller.coredump();
        }
        if (!self.charmode) {
            self.interrupt_controller.set(true, 4, @intFromEnum(arch.Interrupt.KeyboardScancode));
        }
    }
};
