# Go Interpreter Documentation

## Overview

This document provides an overview of the Go-based file operations interpreter, a re-implementation of an existing Lua script. The interpreter allows users to perform various file system operations using a simple command-line interface or by executing a script containing a sequence of commands. This re-implementation aims to provide a more robust and performant solution while maintaining the original functionality.

## Features

The interpreter supports the following file system operations:

*   **Rename/Move (`->`)**: Renames or moves a file or directory.
    Example: `oldname.txt -> newname.txt`
*   **Copy (`>>`)**: Copies a file.
    Example: `source.txt >> destination.txt`
*   **Delete (`!`)**: Deletes a file.
    Example: `!file.txt`
*   **Create Directory (`~`)**: Creates a new directory.
    Example: `~new_directory`
*   **Show Content (`$`)**: Displays the content of a file.
    Example: `$file.txt`
*   **Move to Trash (`-`)**: Marks a file for 
deletion (simulated trash bin).
    Example: `-file.txt`
*   **Restore from Trash (`+`)**: Restores a file from the simulated trash bin.
    Example: `+file.txt`
*   **Remove Lines (`%`)**: Removes lines containing a specific text from a file.
    Example: `%file.txt "text_to_remove"`
*   **List Files (`#`)**: Lists files in a directory, optionally filtered by extension.
    Example: `#.` (list all files in current directory), `#mydir/~.txt` (list .txt files in mydir)
*   **Execute File (`@`)**: Executes commands from a specified file.
    Example: `@commands.txt`, `@commands.txt --deny-execute` (denies execution of nested `@` commands)

## Algorithm Analysis

The Go interpreter processes commands sequentially. Each command is parsed based on its leading token or infix operator. The `ExecuteFn` function is responsible for identifying the command type and dispatching it to the appropriate handler function (e.g., `Rename`, `Copy`, `Delete`).

**Path Normalization**: All file paths are normalized using `filepath.Join` to ensure correct handling of relative and absolute paths. The `currentDirectory` field in the `Interpreter` struct maintains the current working directory, similar to a shell environment.

**Error Handling**: Each operation function returns a boolean indicating success and an error object. This allows for robust error reporting and handling.

**Simulated Trash Bin**: The `trashBin` is implemented as a `map[string]bool` where keys are file paths. This is a simple in-memory representation and does not move files to an actual system trash bin. The `CleanupTrash` function removes all files marked in the `trashBin`.

**Command Execution from File**: The `@` command reads a file line by line and executes each line as a separate command. It supports an optional `--deny-execute` flag to prevent recursive execution of `@` commands, enhancing security.

## Testing

Unit tests have been implemented using Go's built-in `testing` package. The `TestInterpreter_Operations` function covers the core functionality of each command. Temporary directories are used to ensure tests are isolated and do not affect the actual file system.

**Test Cases Covered:**

*   `CreateDirectory`
*   `ShowContent`
*   `Copy`
*   `Rename`
*   `RemoveLines`
*   `ListFiles`
*   `Delete`

## Usage

To run the interpreter, compile the `interpreter.go` file:

```bash
go build -o go-interpreter interpreter.go
```

Then execute it with a command string or a file containing commands:

```bash
./go-interpreter "~my_new_directory"
./go-interpreter commands.txt
```

## Development Notes

During the re-implementation from Lua to Go, particular attention was paid to:

*   **Token Conflict Resolution**: The original Lua script had an ambiguity where the `#` character was used both as a comment prefix and for the `LIST_FILES` token. In the Go implementation, comments are strictly denoted by `//` to resolve this conflict, allowing `#` to be exclusively used for `LIST_FILES`.
*   **Robust Path Handling**: Go's `filepath` package was utilized for safer and more consistent path manipulation compared to string concatenation in Lua.
*   **Structured Error Reporting**: Go's error handling mechanism provides clearer and more detailed error messages.

## References

[1] Lua 5.1 Reference Manual: https://www.lua.org/manual/5.1/
[2] The Go Programming Language Specification: https://go.dev/ref/spec
