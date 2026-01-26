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
	files, err := filepath.Glob("*.json")
	if err != nil {
		log.Fatalf("failed to list JSON files: %v", err)
	}
	if len(files) == 0 {
		log.Println("No JSON files found in the current directory.")
	}
	for _, file := range files {
		f := file
		route := "/" + f
		http.HandleFunc(route, func(w http.ResponseWriter, r *http.Request) {
			if r.Method != http.MethodGet {
				http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
				return
			}
			data, err := os.ReadFile(f)
			if err != nil {
				http.Error(w, f+" not found", http.StatusInternalServerError)
				log.Printf("error reading %s: %v", f, err)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			w.Write(data)
		})
		log.Printf("Serving %s at http://0.0.0.0%s", f, route)
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		var sb strings.Builder
		sb.WriteString("<h1>Available JSON files</h1><ul>")
		for _, f := range files {
			sb.WriteString("<li><a href='/" + f + "'>" + f + "</a></li>")
		}
		sb.WriteString("</ul>")
		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(sb.String()))
	})
	log.Printf("Starting server on %s...", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
