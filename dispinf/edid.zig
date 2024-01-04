const std = @import("std");
const builtin = @import("builtin");
const Self = @This();

pub const Header = extern struct {
    magic: [8]u8,
    manufacturer: u16,
    product: [2]u8,
    serialNo: [4]u8,
    manufacturerWeek: u8,
    _manufacturerYear: u8,
    version: u8,
    revision: u8,

    pub fn format(self: *const Header, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        const monthDay = self.manufacturerMonthAndDay();

        try writer.writeAll(@typeName(Header));
        try writer.print("{{ .magic = {any}, .manufacturer = {s}, .product = {any}, .serialNo = {any}, .manufacturerDay = {}, .manufacturerWeek = {}, .manufacturerMonth = {s}, .manufacturerYear = {}, .version = {}, .revision = {} }}", .{
            self.magic,
            self.manufacturerString(),
            self.product,
            self.serialNo,
            monthDay.day_index,
            self.manufacturerWeek,
            @tagName(monthDay.month),
            self.manufacturerYear(),
            self.version,
            self.revision,
        });
    }

    pub fn manufacturerString(self: *const Header) []const u8 {
        var value: [3]u8 = undefined;
        value[0] = '@' + @as(u8, @intCast((self.manufacturer & 0x007c) >> 2));
        value[1] = '@' + @as(u8, @intCast((((self.manufacturer & 0x0003) >> 0) << 3) | (((self.manufacturer & 0xe000) >> 13) << 0)));
        value[2] = '@' + @as(u8, @intCast((self.manufacturer & 0x1f00) >> 8));
        return &value;
    }

    pub inline fn manufacturerYear(self: *const Header) u16 {
        return @as(u16, @intCast(self._manufacturerYear)) + @as(u16, 1990);
    }

    pub fn manufacturerMonthAndDay(self: *const Header) std.time.epoch.MonthAndDay {
        const yearAndDay = std.time.epoch.YearAndDay{
            .year = self.manufacturerYear() - std.time.epoch.epoch_year,
            .day = @as(u9, @intCast(self.manufacturerWeek % 53)) * @as(u9, 7),
        };
        return yearAndDay.calculateMonthDay();
    }

    pub inline fn manufacturerMonth(self: *const Header) std.time.epoch.Month {
        return self.manufacturerMonthAndDay().month;
    }

    pub inline fn manufacturerDay(self: *const Header) u5 {
        return self.manufacturerMonthAndDay().day_index;
    }
};

pub const VideoInputDefinition = packed struct(u8) {
    vsync: u1,
    greenSync: u1,
    compositeSync: u1,
    sepSync: u1,
    blank2blackSetup: u1,
    sigLevelStd: u2,
    digital: u1,
};

pub const FeatureSupport = packed struct(u8) {
    defaultGtf: u1,
    prefTimingMode: u1,
    stdDefColorSpace: u1,
    displayType: u2,
    activeOff: u1,
    @"suspend": u1,
    standby: u1,
};

pub const ColorCharacteristics = extern struct {
    lows: Lows,
    red: Position,
    green: Position,
    blue: Position,
    white: Position,

    pub const Lows = packed struct(u16) {
        green: Field,
        red: Field,
        white: Field,
        blue: Field,

        pub const Field = packed struct(u4) {
            y: u2,
            x: u2,
        };
    };

    pub const Position = extern struct {
        x: u8,
        y: u8,
    };
};

pub const EstTimings = packed struct {
    @"800x600@60": u1,
    @"800x600@56": u1,
    @"640x480@75": u1,
    @"640x480@72": u1,
    @"640x480@67": u1,
    @"640x480@60": u1,
    @"720x400@88": u1,
    @"720x400@70": u1,
    @"1280x1024@75": u1,
    @"1024x768@75": u1,
    @"1024x768@70": u1,
    @"1024x768@60": u1,
    @"1024x768@87": u1,
    @"832x624@75": u1,
    @"800x600@75": u1,
    @"800x600@72": u1,
};

pub const ManufacturerTimings = packed struct {
    reserved: u7,
    @"1152x870@75": u1,
};

pub const StdTimingDesc = packed struct {
    horizActivePixels: u8,
    refreshRate: u6,
    imgAspectRatio: u2,
};

pub const MonitorDesc = extern struct {
    flags0: u16,
    flags1: u8,
    tag: u8,
    flags2: u8,
    data: [13]u8,
};

pub const DetailedTimingDesc = packed struct {
    pixelClock: u16,
    horizActiveLo: u8,
    horizBlankingLo: u8,
    horizBlankingHi: u4,
    horizActiveHi: u4,
    vertActiveLo: u8,
    vertBlankingLo: u8,
    vertBlankingHi: u4,
    vertActiveHi: u4,
    horizSyncOffsetLo: u8,
    horizSyncPulseWidthLo: u8,
    vertSyncPulseWidthLo: u4,
    vertSyncOffsetLo: u4,
    vertSyncPulseWidthHi: u2,
    vertSyncOffsetHi: u2,
    horizSyncPulseWidthHi: u2,
    horizSyncOffsetHi: u2,
    horizImgSizeLo: u8,
    vertImgSizeLo: u8,
    vertImgSizeHi: u4,
    horizImgSizeHi: u4,
    horizBorder: u8,
    vertBorder: u8,
    flags: Flags,

    pub const Flags = packed struct(u8) {
        stereoModeLo: u1,
        sigPulsePol: u1,
        sigSerrPol: u1,
        sigSync: u2,
        stereoModeHi: u2,
        interlaced: u1,
    };
};

pub const DetailedTiming = extern struct {
    monitor: MonitorDesc,
    timingData: [@sizeOf(DetailedTimingDesc)]u8,

    pub inline fn timing(self: *const DetailedTiming) *align(2) const DetailedTimingDesc {
        return std.mem.bytesAsValue(DetailedTimingDesc, &self.timingData);
    }

    pub fn format(self: *const DetailedTiming, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        try writer.writeAll(@typeName(DetailedTiming));
        try writer.print("{{ .monitor = {}, .timing = {} }}", .{
            self.monitor,
            self.timing(),
        });
    }
};

hdr: Header,
videoInputDefinition: VideoInputDefinition,
maxHorizImageSize: u8,
maxVertImageSize: u8,
displayTransferCharact: u8,
featureSupport: FeatureSupport,
colorCharacteristics: ColorCharacteristics,
estTimings: EstTimings,
manufacturerTimings: ManufacturerTimings,
stdTiming: [6]StdTimingDesc,
detailedTimings: [4]DetailedTiming,
extCount: u8,
checksum: u8,

pub fn init(reader: anytype) !Self {
    const hdr = try reader.readStruct(Header);
    if (!std.mem.eql(u8, &hdr.magic, &.{ 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0 })) return error.InvalidMagic;

    const videoInputDefinition = try reader.readStruct(VideoInputDefinition);
    const maxHorizImageSize = try reader.readInt(u8, builtin.cpu.arch.endian());
    const maxVertImageSize = try reader.readInt(u8, builtin.cpu.arch.endian());
    const displayTransferCharact = try reader.readInt(u8, builtin.cpu.arch.endian());
    const featureSupport = try reader.readStruct(FeatureSupport);
    const colorCharacteristics = try reader.readStruct(ColorCharacteristics);
    const estTimings = try reader.readStruct(EstTimings);
    const manufacturerTimings = try reader.readStruct(ManufacturerTimings);

    var stdTiming: [6]StdTimingDesc = undefined;
    for (&stdTiming) |*t| t.* = try reader.readStruct(StdTimingDesc);

    var detailedTimings: [4]DetailedTiming = undefined;
    for (&detailedTimings) |*t| t.* = try reader.readStruct(DetailedTiming);

    const extCount = try reader.readInt(u8, builtin.cpu.arch.endian());
    const checksum = try reader.readInt(u8, builtin.cpu.arch.endian());

    return .{
        .hdr = hdr,
        .videoInputDefinition = videoInputDefinition,
        .maxHorizImageSize = maxHorizImageSize,
        .maxVertImageSize = maxVertImageSize,
        .displayTransferCharact = displayTransferCharact,
        .featureSupport = featureSupport,
        .colorCharacteristics = colorCharacteristics,
        .estTimings = estTimings,
        .manufacturerTimings = manufacturerTimings,
        .stdTiming = stdTiming,
        .detailedTimings = detailedTimings,
        .extCount = extCount,
        .checksum = checksum,
    };
}

pub fn initBuffer(buff: []const u8) !Self {
    var stream = std.io.fixedBufferStream(buff);
    return try init(stream.reader());
}

pub fn initFile(file: std.fs.File) !Self {
    return try init(file.reader());
}
