pub const McType = enum {
    bedrock,
    pc,

    pub fn toString(self: McType) []const u8 {
        return switch (self) {
            .bedrock => "bedrock",
            .pc => "pc",
        };
    }
};
