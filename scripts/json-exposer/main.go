package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	const addr = ":8080"
	const confDir = "confs"

	// Look for JSON files specifically inside the confs/ directory
	pattern := filepath.Join(confDir, "*.json")
	files, err := filepath.Glob(pattern)
	if err != nil {
		log.Fatalf("failed to list JSON files: %v", err)
	}

	if len(files) == 0 {
		log.Printf("No JSON files found in the %s directory.", confDir)
	}

	for _, filePath := range files {
		// filePath will be "confs/cpu.json"
		// fileName will be "cpu.json"
		fileName := filepath.Base(filePath)
		
		// Capture the current path for the closure
		currentPath := filePath
		route := "/" + fileName

		http.HandleFunc(route, func(w http.ResponseWriter, r *http.Request) {
			if r.Method != http.MethodGet {
				http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
				return
			}
			
			// Always read from disk on every request to ensure "live" updates
			data, err := os.ReadFile(currentPath)
			if err != nil {
				http.Error(w, fileName+" not found", http.StatusNotFound)
				log.Printf("error reading %s: %v", currentPath, err)
				return
			}
			
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			w.Write(data)
		})
		log.Printf("Serving %s at http://0.0.0.0%s", currentPath, route)
	}

	// Index page showing available files
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		var sb strings.Builder
		sb.WriteString("<h1>Available JSON files</h1><ul>")
		for _, filePath := range files {
			fileName := filepath.Base(filePath)
			sb.WriteString("<li><a href='/" + fileName + "'>" + fileName + "</a></li>")
		}
		sb.WriteString("</ul>")
		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(sb.String()))
	})

	log.Printf("Starting server on %s...", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}