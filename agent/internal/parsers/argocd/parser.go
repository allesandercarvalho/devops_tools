package argocd

import (
	"os"
	"regexp"
	"strings"
)

type ArgoAppInfo struct {
	Content        string
	Name           string
	RepoURL        string
	TargetRevision string
	Destination    string
}

func Parse(path string) (*ArgoAppInfo, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	contentStr := string(content)

	// Check if it's an ArgoCD Application
	if !strings.Contains(contentStr, "kind: Application") || !strings.Contains(contentStr, "argoproj.io/v1alpha1") {
		return nil, nil // Not an ArgoCD app
	}

	info := &ArgoAppInfo{
		Content: contentStr,
	}

	// Simple regex parsing
	nameRegex := regexp.MustCompile(`metadata:\s*\n\s*name:\s*([^\s]+)`)
	repoRegex := regexp.MustCompile(`repoURL:\s*([^\s]+)`)
	revisionRegex := regexp.MustCompile(`targetRevision:\s*([^\s]+)`)
	destRegex := regexp.MustCompile(`server:\s*([^\s]+)`)

	if match := nameRegex.FindStringSubmatch(contentStr); len(match) > 1 {
		info.Name = match[1]
	}
	if match := repoRegex.FindStringSubmatch(contentStr); len(match) > 1 {
		info.RepoURL = match[1]
	}
	if match := revisionRegex.FindStringSubmatch(contentStr); len(match) > 1 {
		info.TargetRevision = match[1]
	}
	if match := destRegex.FindStringSubmatch(contentStr); len(match) > 1 {
		info.Destination = match[1]
	}

	return info, nil
}
