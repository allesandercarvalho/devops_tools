package kubectl

import (
	"os"
	"regexp"
	"strings"
)

type KubeConfigInfo struct {
	Content  string
	Clusters []string
	Contexts []string
	Users    []string
}

func Parse(path string) (*KubeConfigInfo, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	contentStr := string(content)

	info := &KubeConfigInfo{
		Content: contentStr,
	}

	// Simple regex parsing for kubeconfig
	clusterRegex := regexp.MustCompile(`- name:\s*([^\s]+)`)
	contextRegex := regexp.MustCompile(`- context:[\s\S]*?name:\s*([^\s]+)`)

	// Extract clusters
	clusterMatches := clusterRegex.FindAllStringSubmatch(contentStr, -1)
	for _, match := range clusterMatches {
		if len(match) > 1 && !contains(info.Clusters, match[1]) {
			info.Clusters = append(info.Clusters, match[1])
		}
	}

	// Extract contexts
	contextMatches := contextRegex.FindAllStringSubmatch(contentStr, -1)
	for _, match := range contextMatches {
		if len(match) > 1 {
			info.Contexts = append(info.Contexts, match[1])
		}
	}

	// Extract users (simplified)
	lines := strings.Split(contentStr, "\n")
	inUsers := false
	for _, line := range lines {
		if strings.Contains(line, "users:") {
			inUsers = true
			continue
		}
		if inUsers && strings.Contains(line, "- name:") {
			userRegex := regexp.MustCompile(`- name:\s*([^\s]+)`)
			if match := userRegex.FindStringSubmatch(line); len(match) > 1 {
				info.Users = append(info.Users, match[1])
			}
		}
		if inUsers && !strings.HasPrefix(strings.TrimSpace(line), "-") && !strings.HasPrefix(strings.TrimSpace(line), "name:") {
			inUsers = false
		}
	}

	return info, nil
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
