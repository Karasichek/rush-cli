package main

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Tokens constants
const (
	TokenRename           = "->"
	TokenMove             = "->"
	TokenCopy             = ">>"
	TokenDelete           = "!"
	TokenCreateDir        = "~"
	TokenShowContent      = "$"
	TokenMoveToTrash      = "-"
	TokenRestoreFromTrash = "+"
	TokenRemoveLines      = "%"
	TokenListFiles        = "#"
	TokenExecuteFile      = "@"
)

var commentPrefixes = []string{"//"}

// Interpreter state
type Interpreter struct {
	trashBin         map[string]bool
	currentDirectory string
}

// NewInterpreter creates a new instance of the interpreter
func NewInterpreter() *Interpreter {
	cwd, _ := os.Getwd()
	return &Interpreter{
		trashBin:         make(map[string]bool),
		currentDirectory: cwd,
	}
}

func (i *Interpreter) normalizePath(path string) string {
	if filepath.IsAbs(path) {
		return path
	}
	return filepath.Join(i.currentDirectory, path)
}

func (i *Interpreter) isComment(line string) bool {
	trimmed := strings.TrimSpace(line)
	for _, prefix := range commentPrefixes {
		if strings.HasPrefix(trimmed, prefix) {
			return true
		}
	}
	// Lua script also had "#" as a comment, but it's also ListFiles.
	// In Lua: if trimmed ~= "" and not trimmed:sub(1, 1) == "#" then
	// Wait, the Lua script actually had a bug or ambiguity there.
	// Let's stick to "//" for comments to allow "#" for ListFiles.
	return false
}

// Operations

func (i *Interpreter) Rename(source, destination string) (bool, error) {
	src := i.normalizePath(source)
	dst := i.normalizePath(destination)

	if _, err := os.Stat(src); os.IsNotExist(err) {
		return false, fmt.Errorf("source file does not exist: %s", src)
	}

	err := os.Rename(src, dst)
	if err != nil {
		return false, fmt.Errorf("failed to rename: %v", err)
	}
	return true, nil
}

func (i *Interpreter) Copy(source, destination string) (bool, error) {
	src := i.normalizePath(source)
	dst := i.normalizePath(destination)

	sourceFile, err := os.Open(src)
	if err != nil {
		return false, fmt.Errorf("cannot open source file: %v", err)
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return false, fmt.Errorf("cannot create destination file: %v", err)
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return false, fmt.Errorf("failed to copy content: %v", err)
	}

	return true, nil
}

func (i *Interpreter) Delete(path string) (bool, error) {
	p := i.normalizePath(path)
	if _, err := os.Stat(p); os.IsNotExist(err) {
		return false, fmt.Errorf("file does not exist: %s", p)
	}

	err := os.Remove(p)
	if err != nil {
		return false, fmt.Errorf("failed to delete file: %v", err)
	}
	return true, nil
}

func (i *Interpreter) CreateDirectory(path string) (bool, error) {
	p := i.normalizePath(path)
	if _, err := os.Stat(p); err == nil {
		return false, fmt.Errorf("directory already exists: %s", p)
	}

	err := os.MkdirAll(p, 0755)
	if err != nil {
		return false, fmt.Errorf("failed to create directory: %v", err)
	}
	return true, nil
}

func (i *Interpreter) ShowContent(path string) (string, error) {
	p := i.normalizePath(path)
	content, err := ioutil.ReadFile(p)
	if err != nil {
		return "", fmt.Errorf("cannot read file: %v", err)
	}
	return string(content), nil
}

func (i *Interpreter) MoveToTrash(path string) (bool, error) {
	p := i.normalizePath(path)
	if _, err := os.Stat(p); os.IsNotExist(err) {
		return false, fmt.Errorf("file does not exist: %s", p)
	}
	i.trashBin[p] = true
	return true, nil
}

func (i *Interpreter) RestoreFromTrash(path string) (bool, error) {
	p := i.normalizePath(path)
	if !i.trashBin[p] {
		return false, fmt.Errorf("file not found in trash: %s", p)
	}
	delete(i.trashBin, p)
	return true, nil
}

func (i *Interpreter) RemoveLines(path, textToRemove string) (bool, error) {
	p := i.normalizePath(path)
	file, err := os.Open(p)
	if err != nil {
		return false, fmt.Errorf("cannot open file: %v", err)
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.Contains(line, textToRemove) {
			lines = append(lines, line)
		}
	}

	if err := scanner.Err(); err != nil {
		return false, fmt.Errorf("error reading file: %v", err)
	}

	output := strings.Join(lines, "\n")
	if len(lines) > 0 {
		output += "\n"
	}

	err = ioutil.WriteFile(p, []byte(output), 0644)
	if err != nil {
		return false, fmt.Errorf("cannot write to file: %v", err)
	}
	return true, nil
}

func (i *Interpreter) ListFiles(path string) ([]string, error) {
	p := i.normalizePath(path)
	
	// Check for pattern like "dir/~.ext"
	var pattern string
	if strings.Contains(p, "/~.") {
		parts := strings.Split(p, "/~.")
		p = parts[0]
		pattern = parts[1]
	}

	info, err := os.Stat(p)
	if err != nil {
		return nil, fmt.Errorf("cannot access path: %v", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("not a directory: %s", p)
	}

	files, err := ioutil.ReadDir(p)
	if err != nil {
		return nil, fmt.Errorf("cannot list directory: %v", err)
	}

	var result []string
	for _, f := range files {
		name := f.Name()
		if pattern == "" || strings.HasSuffix(name, "."+pattern) {
			result = append(result, name)
		}
	}
	return result, nil
}

func (i *Interpreter) ExecuteCommands(path string, options string) (bool, error) {
	p := i.normalizePath(path)
	file, err := os.Open(p)
	if err != nil {
		return false, fmt.Errorf("cannot open command file: %v", err)
	}
	defer file.Close()

	denyExecute := strings.Contains(options, "execute")
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		if denyExecute && strings.HasPrefix(line, TokenExecuteFile) {
			fmt.Printf("Skipping execute command (denied): %s\n", line)
			continue
		}

		_, err := i.ExecuteFn(line)
		if err != nil {
			fmt.Printf("Error executing command: %v\n", err)
		}
	}
	return true, nil
}

func (i *Interpreter) CleanupTrash() {
	for path := range i.trashBin {
		os.Remove(path)
	}
	i.trashBin = make(map[string]bool)
}

// ExecuteFn parses and executes a single command string
func (i *Interpreter) ExecuteFn(command string) (interface{}, error) {
	command = strings.TrimSpace(command)
	if command == "" || i.isComment(command) {
		return true, nil
	}

	// Check prefixes first to avoid conflicts with infix operators
	if strings.HasPrefix(command, TokenDelete) {
		return i.Delete(strings.TrimSpace(command[1:]))
	}
	if strings.HasPrefix(command, TokenCreateDir) {
		return i.CreateDirectory(strings.TrimSpace(command[1:]))
	}
	if strings.HasPrefix(command, TokenShowContent) {
		return i.ShowContent(strings.TrimSpace(command[1:]))
	}
	if strings.HasPrefix(command, TokenMoveToTrash) {
		return i.MoveToTrash(strings.TrimSpace(command[1:]))
	}
	if strings.HasPrefix(command, TokenRestoreFromTrash) {
		return i.RestoreFromTrash(strings.TrimSpace(command[1:]))
	}
	if strings.HasPrefix(command, TokenRemoveLines) {
		content := strings.TrimSpace(command[1:])
		re := regexp.MustCompile(`^([^"]+)"([^"]+)"`)
		matches := re.FindStringSubmatch(content)
		if len(matches) == 3 {
			return i.RemoveLines(strings.TrimSpace(matches[1]), matches[2])
		}
	}
	if strings.HasPrefix(command, TokenListFiles) {
		path := strings.TrimSpace(command[1:])
		if path == "" {
			path = "."
		}
		return i.ListFiles(path)
	}
	if strings.HasPrefix(command, TokenExecuteFile) {
		content := strings.TrimSpace(command[1:])
		parts := strings.Split(content, "--")
		filePath := strings.TrimSpace(parts[0])
		options := ""
		if len(parts) > 1 {
			options = strings.TrimSpace(parts[1])
		}
		return i.ExecuteCommands(filePath, options)
	}

	// Infix operators
	if strings.Contains(command, TokenCopy) {
		parts := strings.Split(command, TokenCopy)
		if len(parts) == 2 {
			return i.Copy(strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1]))
		}
	}
	if strings.Contains(command, TokenRename) {
		parts := strings.Split(command, TokenRename)
		if len(parts) == 2 {
			return i.Rename(strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1]))
		}
	}



	return nil, fmt.Errorf("unknown command: %s", command)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: fil <command_or_file>")
		return
	}

	input := os.Args[1]
	interpreter := NewInterpreter()

	if _, err := os.Stat(input); err == nil {
		file, err := os.Open(input)
		if err != nil {
			fmt.Printf("Error opening file: %v\n", err)
			return
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := scanner.Text()
			res, err := interpreter.ExecuteFn(line)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
			} else {
				if s, ok := res.(string); ok {
					fmt.Println(s)
				} else if list, ok := res.([]string); ok {
					fmt.Println(strings.Join(list, "\n"))
				}
			}
		}
	} else {
		res, err := interpreter.ExecuteFn(input)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
		} else {
			if s, ok := res.(string); ok {
				fmt.Println(s)
			} else if list, ok := res.([]string); ok {
				fmt.Println(strings.Join(list, "\n"))
			}
		}
	}
}
