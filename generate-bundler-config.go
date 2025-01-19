package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Config struct {
	Main    string                 `json:"main"`
	Modules map[string]string      `json:"modules"`
	Output  string                 `json:"output"`
	Const   map[string]interface{} `json:"const"`
}

var cfg = Config{
	Main:    "\\src\\init.lua",
	Modules: map[string]string{},
	Output:  "\\dist\\pvz-release.lua",
	Const: map[string]interface{}{
		"LUBU_BUILDING_DATE": time.Now().Unix(),
	},
}

func main() {
	err := filepath.Walk("./src", func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() && strings.HasSuffix(path, ".lua") && path != cfg.Main {
			cfg.Modules[getFileModuleName(path)] = "\\" + path
		}
		return nil
	})
	if err != nil {
		panic(err)
	}
	bytes, err := json.Marshal(cfg)
	if err != nil {
		panic(err)
	}
	os.WriteFile("./bundle-config.json", []byte(bytes), 0644)
	fmt.Println("Done, saved to ./bundle-config.json")
}

func getFileModuleName(path string) string {
	parts := strings.Split(strings.ReplaceAll(path, ".lua", ""), "\\")
	return strings.Join(parts[1:], ".")
}
