# zmcdata

A Zig library for loading and parsing Minecraft data from the [minecraft-data](https://github.com/PrismarineJS/minecraft-data) project.

## Usage

```zig
const std = @import("std");
const zmcdata = @import("zmcdata");
const schema = @import("zmcdata").schema;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var data = zmcdata.init(allocator, .pc);
    defer data.deinit();

    try data.load("1.20.1");

    const blocks = try data.get(schema.Blocks, "blocks");
    defer blocks.deinit();

    for (blocks.value) |block| {
        std.debug.print("Block: {s}\n", .{block.name});
    }
}
```

## Building

To build the library, run:

```sh
zig build
```

To run the tests, run:

```sh
zig build test
```

## Dependencies

This library depends on the `minecraft-data` project. The Zig build system will automatically fetch the dependency when you build the project.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
