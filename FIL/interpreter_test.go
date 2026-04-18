package main

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestInterpreter_Operations(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "interpreter_test")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tempDir)

	i := NewInterpreter()
	i.currentDirectory = tempDir

	// Test Create Directory (~)
	t.Run("CreateDirectory", func(t *testing.T) {
		_, err := i.ExecuteFn("~testdir")
		if err != nil {
			t.Errorf("Failed to create directory: %v", err)
		}
		if _, err := os.Stat(filepath.Join(tempDir, "testdir")); os.IsNotExist(err) {
			t.Error("Directory was not created")
		}
	})

	// Test Create File and Show Content ($)
	t.Run("ShowContent", func(t *testing.T) {
		filePath := filepath.Join(tempDir, "testfile.txt")
		content := "Hello, Go!"
		err := ioutil.WriteFile(filePath, []byte(content), 0644)
		if err != nil {
			t.Fatal(err)
		}

		res, err := i.ExecuteFn("$testfile.txt")
		if err != nil {
			t.Errorf("Failed to show content: %v", err)
		}
		if res.(string) != content {
			t.Errorf("Expected content %q, got %q", content, res)
		}
	})

	// Test Copy (>>)
	t.Run("Copy", func(t *testing.T) {
		_, err := i.ExecuteFn("testfile.txt >> copy.txt")
		if err != nil {
			t.Errorf("Failed to copy: %v", err)
		}
		if _, err := os.Stat(filepath.Join(tempDir, "copy.txt")); os.IsNotExist(err) {
			t.Error("Copy was not created")
		}
	})

	// Test Rename (->)
	t.Run("Rename", func(t *testing.T) {
		_, err := i.ExecuteFn("copy.txt -> renamed.txt")
		if err != nil {
			t.Errorf("Failed to rename: %v", err)
		}
		if _, err := os.Stat(filepath.Join(tempDir, "renamed.txt")); os.IsNotExist(err) {
			t.Error("File was not renamed")
		}
	})

	// Test Remove Lines (%)
	t.Run("RemoveLines", func(t *testing.T) {
		filePath := filepath.Join(tempDir, "lines.txt")
		content := "line1\nline2\nline3\n"
		err := ioutil.WriteFile(filePath, []byte(content), 0644)
		if err != nil {
			t.Fatal(err)
		}

		_, err = i.ExecuteFn("%lines.txt \"line2\"")
		if err != nil {
			t.Errorf("Failed to remove lines: %v", err)
		}

		newContent, _ := ioutil.ReadFile(filePath)
		if strings.Contains(string(newContent), "line2") {
			t.Error("Line was not removed")
		}
	})

	// Test List Files (#)
	t.Run("ListFiles", func(t *testing.T) {
		res, err := i.ExecuteFn("#.")
		if err != nil {
			t.Errorf("Failed to list files: %v", err)
		}
		files, ok := res.([]string)
		if !ok {
			t.Fatalf("Expected []string, got %T", res)
		}
		found := false
		for _, f := range files {
			if f == "renamed.txt" {
				found = true
				break
			}
		}
		if !found {
			t.Error("File renamed.txt not found in listing")
		}
	})

	// Test Delete (!)
	t.Run("Delete", func(t *testing.T) {
		_, err := i.ExecuteFn("!renamed.txt")
		if err != nil {
			t.Errorf("Failed to delete: %v", err)
		}
		if _, err := os.Stat(filepath.Join(tempDir, "renamed.txt")); err == nil {
			t.Error("File was not deleted")
		}
	})
}
