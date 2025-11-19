# Zig Minecraft Data Wrapper

A Zig wrapper for the `minecraft-data` library, providing easy access to Minecraft data in a statically typed way.

## Features

*   Provides Zig structs for all `minecraft-data` types (blocks, items, entities, etc.).
*   Loads data for a specific Minecraft version.
*   Provides a simple API for accessing the data.
*   Uses Zig's error handling to report errors.
*   Aims to be memory efficient and performant.

## API Architecture

The wrapper is designed to be modular and easy to use. The main components of the API are:

### Core Module (`zmcdata.zig`)

This is the main entry point for the library. It defines the `MinecraftData` struct, which is the main handle for accessing all the Minecraft data.

### `Zmcdata` Struct

The `Zmcdata` struct is the central manager for all Minecraft data. It holds an allocator and a collection of all the loaded data for different versions.

```zig
const zmcdata = @import("zmcdata");

// Initialize the Zmcdata manager
var zmc = zmcdata.Zmcdata.init(std.heap.page_allocator);
defer zmc.deinit();

// Load the data for a specific version
const datav1_21_8 = try zmc.load("1.21.8");

// The memory for datav1_21_8 is managed by zmc, and will be freed when zmc.deinit() is called.

const stone = datav1_21_8.blocks.get("stone").?;
std.debug.print("Stone ID: {}\n", .{stone.id});
```

### Data Modules

The library is organized into modules, where each module corresponds to a data type in `minecraft-data`. For example:

*   `zmcdata/block.zig`: Defines the `Block` struct and related types.
*   `zmcdata/item.zig`: Defines the `Item` struct and related types.
*   `zmcdata/entity.zig`: Defines the `Entity` struct and related types.
*   ...and so on for all other data types.

### Data Structs

Each data module defines Zig structs that mirror the structure of the corresponding JSON data in `minecraft-data`. For example, the `zmcdata/block.zig` module would define a `Block` struct like this:

```zig
const Block = struct {
    id: u16,
    displayName: []const u8,
    name: []const u8,
    hardness: ?f32,
    stackSize: u8,
    diggable: bool,
    boundingBox: BoundingBox,
    material: ?[]const u8,
    // ... and so on
};
```

### Loading Data

The `MinecraftData.load()` function is responsible for loading the data for a specific Minecraft version. It performs the following steps:

1.  Reads the `dataPaths.json` file to find the data paths for the specified version.
2.  For each data type, it reads the corresponding JSON file.
3.  It parses the JSON data and populates the Zig structs.
4.  It returns a `MinecraftData` struct with all the loaded data.

The `load` function will return an error if the specified version is not found, or if there is an error reading or parsing the data files.

### Handling Different Minecraft Versions

The `minecraft-data` library uses a clever system to manage data across different versions, and this wrapper will leverage that system. Not every version of Minecraft has a complete set of data files. Instead, the `dataPaths.json` file maps each version to the correct data file, even if that file is from a different version.

For example, if you request version `1.20.1`:

```zig
const mc_data = try zmcdata.MinecraftData.load("1.20.1");
```

The loader will look up `"1.20.1"` in `dataPaths.json`. It will find that the `blocks` data for this version is located in the `pc/1.20` directory. The wrapper will then automatically load `.../data/pc/1.20/blocks.json`.

This means you can request any version of Minecraft that is present in `dataPaths.json`, and the wrapper will automatically find and load the correct data files for you. You don't need to worry about which version a particular data file comes from.

## Usage

Here's an example of how to use the library to get information about a block:

```zig
const std = @import("std");
const zmcdata = @import("zmcdata");

pub fn main() !void {
    // Initialize the Zmcdata manager
    var zmc = zmcdata.Zmcdata.init(std.heap.page_allocator);
    defer zmc.deinit();

    // Load the data for a specific Minecraft version
    const datav1_21_8 = try zmc.load("1.21.8");

    // Get a block by its name
    const block = datav1_21_8.blocks.get("diamond_ore").?;

    // Print some information about the block
    std.debug.print("Block name: {s}\n", .{block.displayName});
    std.debug.print("Hardness: {any}\n", .{block.hardness});
    std.debug.print("Stack size: {}\n", .{block.stackSize});

    // Get a block by its ID
    const block_by_id = datav1_21_8.blocks.getById(56).?;
    std.debug.print("Block name (by ID): {s}\n", .{block_by_id.displayName});
}
```

## Building from Source

To build the project, you need to have Zig 0.15.2 or later installed.

1.  Clone the repository:
    ```sh
    git clone https://github.com/example/zmcdata.git
    cd zmcdata
    ```

2.  Build the project:
    ```sh
    zig build
    ```

3.  Run the example:
    ```sh
    zig build run
    ```

## Dependencies

This project depends on the `minecraft-data` library. The `build.zig` file is configured to automatically fetch the `minecraft-data` dependency and make it available to the project.

```
