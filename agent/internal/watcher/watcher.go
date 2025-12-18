package watcher

import (
	"log"
	"path/filepath"

	"github.com/fsnotify/fsnotify"
)

// Watcher monitors filesystem changes
type Watcher struct {
	watcher *fsnotify.Watcher
	paths   []string
	onChange func(path string, event fsnotify.Op)
}

// New creates a new filesystem watcher
func New(paths []string, onChange func(path string, event fsnotify.Op)) (*Watcher, error) {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}

	return &Watcher{
		watcher:  w,
		paths:    paths,
		onChange: onChange,
	}, nil
}

// Start begins watching the configured paths
func (w *Watcher) Start() error {
	for _, path := range w.paths {
		absPath, err := filepath.Abs(path)
		if err != nil {
			log.Printf("⚠️  Failed to resolve path %s: %v", path, err)
			continue
		}

		if err := w.watcher.Add(absPath); err != nil {
			log.Printf("⚠️  Failed to watch %s: %v", absPath, err)
			continue
		}

		log.Printf("👀 Watching: %s", absPath)
	}

	go w.watch()
	return nil
}

// watch is the main event loop
func (w *Watcher) watch() {
	for {
		select {
		case event, ok := <-w.watcher.Events:
			if !ok {
				return
			}

			// Filter out temporary files and irrelevant events
			if shouldIgnore(event.Name) {
				continue
			}

			log.Printf("📝 File changed: %s [%s]", event.Name, event.Op)

			if w.onChange != nil {
				w.onChange(event.Name, event.Op)
			}

		case err, ok := <-w.watcher.Errors:
			if !ok {
				return
			}
			log.Printf("❌ Watcher error: %v", err)
		}
	}
}

// Close stops the watcher
func (w *Watcher) Close() error {
	return w.watcher.Close()
}

// shouldIgnore checks if a file should be ignored
func shouldIgnore(path string) bool {
	base := filepath.Base(path)
	
	// Ignore temporary files
	if len(base) > 0 && base[0] == '.' {
		return true
	}
	
	// Ignore swap files
	if filepath.Ext(base) == ".swp" || filepath.Ext(base) == ".tmp" {
		return true
	}
	
	return false
}
