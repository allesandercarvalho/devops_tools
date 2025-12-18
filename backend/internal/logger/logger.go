package logger

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

// InitLogger initializes the logger
func InitLogger(logDir string, level string) error {
	Log = logrus.New()

	// Set log level
	logLevel, err := logrus.ParseLevel(level)
	if err != nil {
		logLevel = logrus.InfoLevel
	}
	Log.SetLevel(logLevel)

	// Set formatter
	Log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "level",
			logrus.FieldKeyMsg:   "message",
		},
	})

	// Create log directory if it doesn't exist
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return fmt.Errorf("failed to create log directory: %w", err)
	}

	// Create log file
	logFile := filepath.Join(logDir, fmt.Sprintf("backend-%s.log", time.Now().Format("2006-01-02")))
	file, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}

	// Write to both file and stdout
	mw := io.MultiWriter(os.Stdout, file)
	Log.SetOutput(mw)

	return nil
}

// WithFields creates a new logger entry with fields
func WithFields(fields logrus.Fields) *logrus.Entry {
	if Log == nil {
		Log = logrus.New()
	}
	return Log.WithFields(fields)
}

// Info logs an info message
func Info(msg string, fields ...logrus.Fields) {
	if Log == nil {
		Log = logrus.New()
	}
	if len(fields) > 0 {
		Log.WithFields(fields[0]).Info(msg)
	} else {
		Log.Info(msg)
	}
}

// Error logs an error message
func Error(msg string, err error, fields ...logrus.Fields) {
	if Log == nil {
		Log = logrus.New()
	}
	f := logrus.Fields{"error": err.Error()}
	if len(fields) > 0 {
		for k, v := range fields[0] {
			f[k] = v
		}
	}
	Log.WithFields(f).Error(msg)
}

// Warn logs a warning message
func Warn(msg string, fields ...logrus.Fields) {
	if Log == nil {
		Log = logrus.New()
	}
	if len(fields) > 0 {
		Log.WithFields(fields[0]).Warn(msg)
	} else {
		Log.Warn(msg)
	}
}

// Debug logs a debug message
func Debug(msg string, fields ...logrus.Fields) {
	if Log == nil {
		Log = logrus.New()
	}
	if len(fields) > 0 {
		Log.WithFields(fields[0]).Debug(msg)
	} else {
		Log.Debug(msg)
	}
}
