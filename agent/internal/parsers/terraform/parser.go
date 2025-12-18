package terraform

import (
	"os"
	"regexp"
)

type TerraformInfo struct {
	Content   string
	Resources []string
	Variables []string
}

func Parse(path string) (*TerraformInfo, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	info := &TerraformInfo{
		Content: string(content),
	}

	// Simple regex parsing
	resourceRegex := regexp.MustCompile(`resource\s+"([^"]+)"\s+"([^"]+)"`)
	variableRegex := regexp.MustCompile(`variable\s+"([^"]+)"`)

	resourceMatches := resourceRegex.FindAllStringSubmatch(info.Content, -1)
	for _, match := range resourceMatches {
		if len(match) > 2 {
			info.Resources = append(info.Resources, match[1]+"."+match[2])
		}
	}

	variableMatches := variableRegex.FindAllStringSubmatch(info.Content, -1)
	for _, match := range variableMatches {
		if len(match) > 1 {
			info.Variables = append(info.Variables, match[1])
		}
	}

	return info, nil
}
