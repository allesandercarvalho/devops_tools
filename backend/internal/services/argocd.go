package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"time"

	"github.com/devopstools/backend/internal/logger"
	"github.com/devopstools/backend/internal/models"
)

type ArgoCDService struct{}

func NewArgoCDService() *ArgoCDService {
	return &ArgoCDService{}
}

// ListApplications lists all ArgoCD applications
func (s *ArgoCDService) ListApplications() ([]models.ArgoAppDetail, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "argocd", "app", "list", "-o", "json")
	output, err := cmd.CombinedOutput()
	if err != nil {
		logger.Error("Failed to list argocd apps", err)
		return nil, fmt.Errorf("failed to list apps: %s", string(output))
	}

	var apps []models.ArgoAppDetail
	if err := json.Unmarshal(output, &apps); err != nil {
		// Try to parse as single object if list fails (sometimes CLI behavior varies)
		// Or maybe output is empty
		if len(output) == 0 {
			return []models.ArgoAppDetail{}, nil
		}
		return nil, fmt.Errorf("failed to parse argocd output: %v", err)
	}

	return apps, nil
}

// GetApplication gets details of a specific application
func (s *ArgoCDService) GetApplication(appName string) (*models.ArgoAppDetail, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "argocd", "app", "get", appName, "-o", "json")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to get app %s: %s", appName, string(output))
	}

	var app models.ArgoAppDetail
	if err := json.Unmarshal(output, &app); err != nil {
		return nil, fmt.Errorf("failed to parse app details: %v", err)
	}

	return &app, nil
}

// SyncApplication syncs an application
func (s *ArgoCDService) SyncApplication(appName string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "argocd", "app", "sync", appName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to sync app %s: %s", appName, string(output))
	}

	return nil
}
